# frozen_string_literal: true

require_relative "../test_helper"
require "database_cleaner/active_record"

class ControlledTaskViewModelBuilder < TaskViewModelBuilder
  def initialize(exchanger)
    @exchanger = exchanger
  end

  def change_task_name(event, task)
    @exchanger.exchange!(:message)
    super
  end

  def complete_task(_event, task)
    super
    @exchanger.exchange!(:message)
  end
end

class ConcurrencyBetweenRebuildingTaskViewReadModelsTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    DatabaseCleaner.strategy = :truncation
  end

  def test_concurrent_replay_of_events_and_processing_new_event__expected_that_the_event_is_processed_when_replay_is_finished
    begin
      concurrency_level = ActiveRecord::Base.connection.pool.size - 1
      assert concurrency_level >= 4

      task_id = SecureRandom.uuid
      event_store.append(TaskCreated.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")

      100.times do |i|
        event_store.append(TaskDateAssigned.new(data: { task_id: task_id, due_date: Date.current + i.day }), stream_name: "Task$#{task_id}")
      end
      task_name_changed_newer = TaskNameChanged.new(data: { task_id: task_id, name: "Init name" })
      event_store.append(task_name_changed_newer, stream_name: "Task$#{task_id}")
      last_applied_event = nil

      TaskViewModelBuilder.new.call(task_name_changed_newer)

      Thread.abort_on_exception = true
      exchanger = Concurrent::Exchanger.new

      threads = [
        Thread.new do
          ControlledTaskViewModelBuilder.new(exchanger).rebuild(task_id)
        end,
        Thread.new do
          last_applied_event = TaskCompleted.new(data: { task_id: task_id })
          event_store.append(last_applied_event, stream_name: "Task$#{task_id}")
          exchanger.exchange(:message)
          ControlledTaskViewModelBuilder.new(exchanger).call(last_applied_event)
        end
      ]

      threads.each(&:join)

      task_view_model = TaskViewModel.find(task_id)
      assert_equal last_applied_event.event_id, task_view_model.checkpoint
      assert_equal("completed", task_view_model.status)
      assert_equal("Init name", task_view_model.name)
      assert_equal(Date.current + 99.day, task_view_model.due_date)
    ensure
      ActiveRecord::Base.connection_pool.disconnect!
    end
  end

  teardown { DatabaseCleaner.clean }

  private

  def event_store
    Rails.configuration.event_store
  end
end
