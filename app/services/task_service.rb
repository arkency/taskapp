# frozen_string_literal: true

class TaskService
  def create_task
    uuid = SecureRandom.uuid
    task = Task.new(uuid)
    task.create
    AggregateRoot::Repository.new.store(task, "Task$#{uuid}")
    uuid
  end

  def change_name(task_id, new_name)
    task = find_task(task_id)
    task.change_name(new_name)
    @repository.store(task, "Task$#{task_id}")
  end

  def delete_task(task_id)
    task = find_task(task_id)
    task.delete
    @repository.store(task, "Task$#{task_id}")
  end

  def assign_date(task_id, new_date)
    task = find_task(task_id)
    task.assign_date(new_date)
    @repository.store(task, "Task$#{task_id}")
  end

  def complete_task(task_id)
    task = find_task(task_id)
    task.complete
    @repository.store(task, "Task$#{task_id}")
  end

  def reopen_task(task_id)
    task = find_task(task_id)
    task.reopen
    @repository.store(task, "Task$#{task_id}")
  end

  def find_task(task_id)
    @repository ||= AggregateRoot::Repository.new
    @repository.load(Task.new(task_id), "Task$#{task_id}")
  end

  def task_state(task_id)
    RailsEventStore::Projection
      .from_stream("Task$#{task_id}")
      .init(-> { { status: :open } })
      .when(TaskCreated, ->(state, event) { state[:status] = :open; state[:id] = event.data.fetch(:task_id) })
      .when(TaskCompleted, ->(state, event) { state[:status] = :completed })
      .when(TaskDeleted, ->(state, event) { state[:status] = :deleted })
      .when(TaskReopened, ->(state, event) { state[:status] = :open })
      .when(TaskDateAssigned, ->(state, event) { state[:date] = event.data.fetch(:date) })
      .when(TaskNameChanged, ->(state, event) { state[:name] = event.data.fetch(:name) })
      .run(event_store)
  end

  def completed_tasks_reopened(task_id)
    CompletedTasksReopened.new.for_task(task_id)
  end

  def all_completed_tasks_reopened
    CompletedTasksReopened.new.all
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
