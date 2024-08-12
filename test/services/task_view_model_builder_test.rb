# frozen_string_literal: true

require_relative "../test_helper"

class TaskViewModelBuilderTest < ActiveSupport::TestCase
  def test_builds_the_read_model
    task_id = SecureRandom.uuid
    event_store.publish(TaskCreated.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")
    event_store.publish(TaskNameChanged.new(data: { task_id: task_id, name: "New name" }), stream_name: "Task$#{task_id}")
    event_store.publish(TaskDateAssigned.new(data: { task_id: task_id, due_date: Date.new(2020, 1, 1) }), stream_name: "Task$#{task_id}")
    event_store.publish(TaskCompleted.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")

    perform_enqueued_jobs(only: TaskViewModelBuilder)

    TaskViewModel.find(task_id).tap do |task|
      assert_equal "New name", task.name
      assert_equal Date.new(2020, 1, 1), task.due_date
      assert_equal "completed", task.status
    end
  end

  def test_respects_order_of_name
    task_id = SecureRandom.uuid
    first_name_change = TaskNameChanged.new(data: { task_id:, name: "New name" }, metadata: { timestamp: Time.now - 1.minute })
    second_name_change = TaskNameChanged.new(data: { task_id:, name: "Meh new name" }, metadata: { timestamp: Time.now })
    event_store.publish(TaskCreated.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")
    event_store.publish(first_name_change, stream_name: "Task$#{task_id}")
    event_store.publish(second_name_change, stream_name: "Task$#{task_id}")

    perform_enqueued_jobs(only: TaskViewModelBuilder)

    TaskViewModel.find(task_id).tap do |task|
      assert_equal "Meh new name", task.name
    end
  end

  def test_respects_order_of_due_date
    task_id = SecureRandom.uuid
    first_due_date = TaskDateAssigned.new(data: { task_id:, due_date: Date.new(2020, 1, 1) }, metadata: { timestamp: Time.now - 1.minute })
    second_due_date = TaskDateAssigned.new(data: { task_id:, due_date: Date.new(2020, 1, 2) }, metadata: { timestamp: Time.now })
    event_store.publish(TaskCreated.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")
    event_store.publish(first_due_date, stream_name: "Task$#{task_id}")
    event_store.publish(second_due_date, stream_name: "Task$#{task_id}")

    perform_enqueued_jobs(only: TaskViewModelBuilder)

    TaskViewModel.find(task_id).tap do |task|
      assert_equal Date.new(2020, 1, 2), task.due_date
    end
  end

  def test_respects_order_of_status
    task_id = SecureRandom.uuid
    event_store.publish(TaskCreated.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")
    event_store.publish(TaskCompleted.new(data: { task_id: }, metadata: { timestamp: Time.now }), stream_name: "Task$#{task_id}")
    event_store.publish(TaskCompleted.new(data: { task_id: }, metadata: { timestamp: Time.now - 1.minute }), stream_name: "Task$#{task_id}")

    perform_enqueued_jobs(only: TaskViewModelBuilder)

    TaskViewModel.find(task_id).tap do |task|
      assert_equal "completed", task.status
    end
  end

  def test_doesnt_fail_when_events_come_out_of_order
    task_id = SecureRandom.uuid
    event_store.publish(TaskNameChanged.new(data: { task_id:, name: "Name" }), stream_name: "Task$#{task_id}")
    event_store.publish(TaskCreated.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")

    perform_enqueued_jobs(only: TaskViewModelBuilder)

    TaskViewModel.find(task_id).tap do |task|
      assert_equal "Name", task.name
      assert_equal "open", task.status
    end
  end

  def test_state_after_rebuild_is_the_same_as_after_initial_build
    task_id = SecureRandom.uuid
    event_store.publish(TaskCreated.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")
    event_store.publish(TaskCompleted.new(data: { task_id: }, metadata: { timestamp: Time.now }), stream_name: "Task$#{task_id}")
    event_store.publish(TaskCompleted.new(data: { task_id: }, metadata: { timestamp: Time.now - 1.minute }), stream_name: "Task$#{task_id}")

    perform_enqueued_jobs(only: TaskViewModelBuilder)
    original = TaskViewModel.find(task_id)

    TaskViewModelBuilder.new.rebuild(task_id)

    TaskViewModel.find(task_id).tap do |task|
      assert_equal original.status, task.status
      assert_equal original.checkpoint, task.checkpoint
    end
  end
  
  private

  def event_store
    Rails.configuration.event_store
  end
end

