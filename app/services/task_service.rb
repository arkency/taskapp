# frozen_string_literal: true

class TaskService
  def create_task
    uuid = SecureRandom.uuid
    # task = Task.create_factory_method(uuid) #1
    # task = Task.new # 3
    # task.create(uuid) # 3
    task = Task.new(uuid)
    task.create # 4
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
    # @repository.load(Task.new(task_id), "Task$#{task_id}")  #1
    @repository.load(Task.new(task_id), "Task$#{task_id}") # 3
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
