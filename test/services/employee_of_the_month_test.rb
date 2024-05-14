# frozen_string_literal: true

require_relative "../test_helper"

class EmployeeOfTheMonthTest < ActiveSupport::TestCase
  def test_employee_of_the_month_is_an_employee_with_most_of_completed_tasks
    task_1_id = SecureRandom.uuid
    task_2_id = SecureRandom.uuid
    task_3_id = SecureRandom.uuid

    event_store.publish(EmployeeAssignedToTask.new(data: { task_id: task_1_id, employee_id: 1 }), stream_name: "TaskAssignments$#{task_1_id}")
    event_store.publish(TaskCompleted.new(data: { task_id: task_1_id }), stream_name: "Task$#{task_1_id}")
    event_store.publish(EmployeeAssignedToTask.new(data: { task_id: task_2_id, employee_id: 2 }), stream_name: "TaskAssignments$#{task_2_id}")
    event_store.publish(TaskCompleted.new(data: { task_id: task_2_id }), stream_name: "Task$#{task_2_id}")
    event_store.publish(EmployeeAssignedToTask.new(data: { task_id: task_3_id, employee_id: 1 }), stream_name: "TaskAssignments$#{task_3_id}")
    event_store.publish(TaskCompleted.new(data: { task_id: task_3_id }), stream_name: "Task$#{task_3_id}")

    employee_of_the_month = EmployeeOfTheMonth.new.call

    assert_equal 1, employee_of_the_month[:employee_id]
    assert_equal 2, employee_of_the_month[:completed_tasks]
  end

  def test_it_should_work_no_matter_the_order_of_events
    task_1_id = SecureRandom.uuid
    task_2_id = SecureRandom.uuid
    task_3_id = SecureRandom.uuid

    event_store.publish(TaskCompleted.new(data: { task_id: task_1_id }), stream_name: "Task$#{task_1_id}")
    event_store.publish(TaskCompleted.new(data: { task_id: task_3_id }), stream_name: "Task$#{task_3_id}")
    event_store.publish(TaskCompleted.new(data: { task_id: task_2_id }), stream_name: "Task$#{task_2_id}")
    event_store.publish(EmployeeAssignedToTask.new(data: { task_id: task_1_id, employee_id: 1 }), stream_name: "TaskAssignments$#{task_1_id}")
    event_store.publish(EmployeeAssignedToTask.new(data: { task_id: task_2_id, employee_id: 2 }), stream_name: "TaskAssignments$#{task_2_id}")
    event_store.publish(EmployeeAssignedToTask.new(data: { task_id: task_3_id, employee_id: 1 }), stream_name: "TaskAssignments$#{task_3_id}")

    employee_of_the_month = EmployeeOfTheMonth.new.call

    assert_equal 1, employee_of_the_month[:employee_id]
    assert_equal 2, employee_of_the_month[:completed_tasks]
  end

  def test_when_employee_is_unassigned_from_task_and_another_employee_is_assigned_to_it_then_task_is_counted_for_last_assigned_employee
    task_id = SecureRandom.uuid

    event_store.publish(EmployeeAssignedToTask.new(data: { task_id: task_id, employee_id: 1 }), stream_name: "TaskAssignments$#{task_id}")
    event_store.publish(TaskCompleted.new(data: { task_id: task_id }), stream_name: "Task$#{task_id}")
    event_store.publish(EmployeeUnassignedFromTask.new(data: { task_id: task_id, employee_id: 1 }), stream_name: "TaskAssignments$#{task_id}")
    event_store.publish(EmployeeAssignedToTask.new(data: { task_id: task_id, employee_id: 2 }), stream_name: "TaskAssignments$#{task_id}")

    employee_of_the_month = EmployeeOfTheMonth.new.call

    assert_equal 2, employee_of_the_month[:employee_id]
    assert_equal 1, employee_of_the_month[:completed_tasks]
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
