# frozen_string_literal: true

require_relative "../test_helper"
require "database_cleaner/active_record"

class ConcurrencyBetweenRebuildingTaskViewReadModelsTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  setup do
    DatabaseCleaner.strategy = [:truncation]
  end

  def test_builder
    begin
      concurrency_level = ActiveRecord::Base.connection.pool.size - 1
      assert concurrency_level >= 4

      fail_occurred = false
      wait_for_it = true
      exception = nil
      task_id = SecureRandom.uuid
      event_store.publish(TaskCreated.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")
      perform_enqueued_jobs(only: TaskViewModelBuilder)
      task_name_changed_newer = TaskNameChanged.new(data: { task_id: task_id, name: "Init name" })
      event_store.append(task_name_changed_newer, stream_name: "Task$#{task_id}")

      Thread.abort_on_exception = true
      threads = [
        Thread.new do
          true while wait_for_it
          begin
            task_name_changed_newer.metadata[:sleep] = true
            TaskViewModelBuilder.new.call(task_name_changed_newer)
          rescue StandardError => e
            exception = e
            fail_occurred = true
          end
        end,
        Thread.new do
          true while wait_for_it
          begin
            sleep 1
            task_name_changed_newer = TaskNameChanged.new(data: { task_id: task_id, name: "New name" })
            event_store.append(task_name_changed_newer, stream_name: "Task$#{task_id}")
            TaskViewModelBuilder.new.call(task_name_changed_newer)
          rescue StandardError => e
            exception = e
            fail_occurred = true
          end
        end
      ]
      wait_for_it = false
      threads.each(&:join)

      assert_equal "New name", TaskViewModel.find(task_id).name
      assert fail_occurred
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
