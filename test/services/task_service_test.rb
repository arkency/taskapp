require_relative '../test_helper'

class TaskServiceTest < ActiveSupport::TestCase
  test "publishes event on task creation" do
    uuid = TaskService.new.create_task

    tasks_stream = event_store.read.stream("Task$#{uuid}")
    assert tasks_stream.count.equal?(1)
    assert tasks_stream.last.class.eql?(TaskCreated)
    assert tasks_stream.last.data.fetch(:task_id).eql?(uuid)
  end

  test "change name of task" do
    task_service = TaskService.new
    uuid = task_service.create_task

    task_service.change_name(uuid, "Introduce RailsEventStore to the project")

    tasks_stream = event_store.read.stream("Task$#{uuid}")
    assert tasks_stream.count.equal?(2)
    task_name_changed = tasks_stream.last
    assert task_name_changed.class.eql?(TaskNameChanged)
    assert task_name_changed.data.fetch(:name).eql?("Introduce RailsEventStore to the project")
    assert task_name_changed.data.fetch(:task_id).eql?(uuid)
  end

  test "when task is completed then name cannot be changed" do
    task_service = TaskService.new
    uuid = task_service.create_task
    task_service.complete_task(uuid)
    task_service.change_name(uuid, "Introduce RailsEventStore to the project")

    tasks_stream = event_store.read.stream("Task$#{uuid}")
    assert tasks_stream.count.equal?(2)
    assert tasks_stream.last.class.eql?(TaskCompleted)
  end

  test "task can be completed" do
    task_service = TaskService.new
    uuid = task_service.create_task

    task_service.complete_task(uuid)

    tasks_stream = event_store.read.stream("Task$#{uuid}")
    assert tasks_stream.count.equal?(2)
    task_completed = tasks_stream.last
    assert task_completed.class.eql?(TaskCompleted)
    assert task_completed.data.fetch(:task_id).eql?(uuid)
  end

  test "deleted task cannot be completed" do
    task_service = TaskService.new
    uuid = task_service.create_task
    task_service.delete_task(uuid)

    task_service.complete_task(uuid)

    tasks_stream = event_store.read.stream("Task$#{uuid}")
    assert tasks_stream.count.equal?(2)
    task_deleted = tasks_stream.last
    assert task_deleted.class.eql?(TaskDeleted)
    assert task_deleted.data.fetch(:task_id).eql?(uuid)
  end

  test "task can be deleted" do
    task_service = TaskService.new
    uuid = task_service.create_task

    task_service.delete_task(uuid)

    tasks_stream = event_store.read.stream("Task$#{uuid}")
    assert tasks_stream.count.equal?(2)
    task_deleted = tasks_stream.last
    assert task_deleted.class.eql?(TaskDeleted)
    assert task_deleted.data.fetch(:task_id).eql?(uuid)
  end

  test "completed task can be reopened" do
    task_service = TaskService.new
    uuid = task_service.create_task
    task_service.complete_task(uuid)

    task_service.reopen_task(uuid)

    tasks_stream = event_store.read.stream("Task$#{uuid}")
    assert tasks_stream.count.equal?(3)
    task_reopened = tasks_stream.last
    assert task_reopened.class.eql?(TaskReopened)
    assert task_reopened.data.fetch(:task_id).eql?(uuid)
  end

  test "deleted task cannot be reopened" do
    task_service = TaskService.new
    uuid = task_service.create_task
    task_service.delete_task(uuid)

    task_service.reopen_task(uuid)

    tasks_stream = event_store.read.stream("Task$#{uuid}")
    assert tasks_stream.count.equal?(2)
  end

  test "date can be assigned to task" do
    task_service = TaskService.new
    uuid = task_service.create_task
    task_service.assign_date(uuid, Date.new(2019, 12, 31))

    tasks_stream = event_store.read.stream("Task$#{uuid}")
    assert tasks_stream.count.equal?(2)
    task_date_assigned = tasks_stream.last
    assert task_date_assigned.class.eql?(TaskDateAssigned)
    assert task_date_assigned.data.fetch(:date).eql?(Date.new(2019, 12, 31))
    assert task_date_assigned.data.fetch(:task_id).eql?(uuid)
  end

  test "date of task can be reassigned" do
    task_service = TaskService.new
    uuid = task_service.create_task
    task_service.assign_date(uuid, Date.new(2019, 12, 31))
    task_service.assign_date(uuid, Date.new(2020, 1, 1))

    tasks_stream = event_store.read.stream("Task$#{uuid}")
    assert tasks_stream.count.equal?(3)
    task_date_assigned = tasks_stream.last
    assert task_date_assigned.class.eql?(TaskDateAssigned)
    assert task_date_assigned.data.fetch(:date).eql?(Date.new(2020, 1, 1))
  end

  test "when task is completed date cannot be changed" do
    task_service = TaskService.new
    uuid = task_service.create_task
    task_service.complete_task(uuid)
    task_service.assign_date(uuid, Date.new(2019, 12, 31))

    tasks_stream = event_store.read.stream("Task$#{uuid}")
    assert tasks_stream.count.equal?(2)
    assert tasks_stream.last.class.eql?(TaskCompleted)
  end

  test "when task is deleted name cannot be changed" do
    task_service = TaskService.new
    uuid = task_service.create_task
    task_service.delete_task(uuid)
    task_service.change_name(uuid, "Introduce RailsEventStore to the project")

    tasks_stream = event_store.read.stream("Task$#{uuid}")
    assert tasks_stream.count.equal?(2)
    assert tasks_stream.last.class.eql?(TaskDeleted)
  end

  test "when task is deleted date cannot be changed" do
    task_service = TaskService.new
    uuid = task_service.create_task
    task_service.delete_task(uuid)
    task_service.assign_date(uuid, Date.new(2019, 12, 31))

    tasks_stream = event_store.read.stream("Task$#{uuid}")
    assert tasks_stream.count.equal?(2)
    assert tasks_stream.last.class.eql?(TaskDeleted)
  end

  test "when task is reopened date can be changed" do
    task_service = TaskService.new
    uuid = task_service.create_task
    task_service.complete_task(uuid)
    task_service.reopen_task(uuid)
    task_service.assign_date(uuid, Date.new(2019, 12, 31))

    tasks_stream = event_store.read.stream("Task$#{uuid}")
    assert_equal 4, tasks_stream.count
    task_date_assigned = tasks_stream.last
    assert task_date_assigned.class.eql?(TaskDateAssigned)
    assert task_date_assigned.data.fetch(:date).eql?(Date.new(2019, 12, 31))
  end

  test "build report" do
    task_service = TaskService.new
    uuid_1 = task_service.create_task
    task_service.change_name(uuid_1, "Introduce RailsEventStore to the project")
    task_service.assign_date(uuid_1, Date.new(2019, 12, 31))
    task_service.complete_task(uuid_1)
    task_service.reopen_task(uuid_1)

    task_service.complete_task(uuid_1)
    task_service.reopen_task(uuid_1)

    task_service.complete_task(uuid_1)
    task_service.reopen_task(uuid_1)

    task_service.complete_task(uuid_1)

    report = task_service.completed_tasks_reopened(uuid_1)
    assert report[:completed] == 4
    assert report[:reopened] == 3

    uuid_2 = task_service.create_task
    task_service.change_name(uuid_2, "Introduce RailsEventStore to the project")
    task_service.assign_date(uuid_2, Date.new(2019, 12, 31))
    task_service.complete_task(uuid_2)
    task_service.reopen_task(uuid_2)

    task_service.complete_task(uuid_2)
    task_service.reopen_task(uuid_2)

    task_service.complete_task(uuid_2)
    task_service.reopen_task(uuid_2)

    task_service.complete_task(uuid_2)
    task_service.reopen_task(uuid_2)

    report2 = task_service.all_completed_tasks_reopened
    assert report2.fetch(uuid_1) == 3
    assert report2.fetch(uuid_2) == 4
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
