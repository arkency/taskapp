# frozen_string_literal: true

require_relative '../test_helper'

class CompletedTasksReopenedTest < ActiveSupport::TestCase
  def test_completed_tasks_reopened_for_specific_task
    task_id = SecureRandom.uuid
    different_task_id = SecureRandom.uuid
    event_store.publish(TaskCompleted.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")
    event_store.publish(TaskReopened.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")
    event_store.publish(TaskCompleted.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")
    event_store.publish(TaskReopened.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")
    event_store.publish(TaskReopened.new(data: { task_id: different_task_id }), stream_name: "Task$#{different_task_id}")

    completed_tasks_reopened = CompletedTasksReopened.new.for_task(task_id)

    assert_equal 2, completed_tasks_reopened.fetch(:completed)
    assert_equal 2, completed_tasks_reopened.fetch(:reopened)
  end

  def test_completed_tasks_reopened_for_all_tasks
    task_id = SecureRandom.uuid
    different_task_id = SecureRandom.uuid
    event_store.publish(TaskCompleted.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")
    event_store.publish(TaskReopened.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")
    event_store.publish(TaskCompleted.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")
    event_store.publish(TaskReopened.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")
    event_store.publish(TaskReopened.new(data: { task_id: different_task_id }), stream_name: "Task$#{different_task_id}")

    completed_tasks_reopened = CompletedTasksReopened.new.all

    assert_equal 2, completed_tasks_reopened[task_id]
    assert_equal 1, completed_tasks_reopened[different_task_id]
  end

  def test_no_completed_or_reopened_states_when_nothing_happened_for_task
    completed_tasks_reopened = CompletedTasksReopened.new.for_task(SecureRandom.uuid)

    assert_equal({ completed: 0, reopened: 0 }, completed_tasks_reopened)
  end

  def test_when_nothing_happened_then_there_is_nothing_to_report
    completed_tasks_reopened = CompletedTasksReopened.new.all

    assert_equal({ }, completed_tasks_reopened)
  end


  private

  def event_store
    Rails.configuration.event_store
  end
end
