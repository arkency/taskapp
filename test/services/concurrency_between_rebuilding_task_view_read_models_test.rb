# frozen_string_literal: true

require_relative "../test_helper"
require "database_cleaner/active_record"

class SlowTaskViewModelBuilder < TaskViewModelBuilder
  def initialize(exchanger)
    @exchanger = exchanger
  end

  def change_task_name(event, task)
    @exchanger.exchange!(:message)
    super
  end
end

class ConcurrencyBetweenRebuildingTaskViewReadModelsTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    DatabaseCleaner.strategy = :truncation
  end

  def test_builder
    begin
      exception = nil
      concurrency_level = ActiveRecord::Base.connection.pool.size - 1
      assert concurrency_level >= 4

      unexpected_failure = false
      fail_occurred = false
      task_id = SecureRandom.uuid
      event_store.publish(TaskCreated.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")
      perform_enqueued_jobs(only: TaskViewModelBuilder)
      task_name_changed_newer = TaskNameChanged.new(data: { task_id: task_id, name: "Init name" })
      event_store.append(task_name_changed_newer, stream_name: "Task$#{task_id}")

      Thread.abort_on_exception = true
      exchanger = Concurrent::Exchanger.new

      threads = [
        Thread.new do
          begin
            SlowTaskViewModelBuilder.new(exchanger).call(task_name_changed_newer)
          rescue StandardError => e
            exception = e
            fail_occurred = true
          end
        end,
        Thread.new do
          begin
            task_name_changed_newer = TaskNameChanged.new(data: { task_id: task_id, name: "New name" })
            event_store.append(task_name_changed_newer, stream_name: "Task$#{task_id}")
            TaskViewModelBuilder.new.call(task_name_changed_newer)
            exchanger.exchange(:message)
          rescue StandardError => e
            unexpected_failure = true
          end
        end
      ]

      threads.each(&:join)

      assert_equal "New name", TaskViewModel.find(task_id).name
      assert fail_occurred
      refute unexpected_failure
      assert exception.is_a?(ActiveRecord::StaleObjectError)
    ensure
      ActiveRecord::Base.connection_pool.disconnect!
    end
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
