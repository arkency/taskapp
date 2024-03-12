# frozen_string_literal: true

class TaskService

  def create_task
    uuid = SecureRandom.uuid
    event_store.publish(TaskCreated.new(data: { task_id: uuid }), stream_name: "Task$#{uuid}")
    uuid
  end

  def change_name(task_id, new_name)
    return unless find_task(task_id).status.eql?(:open)
    event_store.publish(TaskNameChanged.new(data: { name: new_name, task_id: }), stream_name: "Task$#{task_id}")
  end

  def delete_task(task_id)
    event_store.publish(TaskDeleted.new(data: { task_id: }), stream_name: "Task$#{task_id}")
  end

  def assign_date(task_id, new_date)
    return unless find_task(task_id).status.eql?(:open)
    event_store.publish(TaskDateAssigned.new(data: { date: new_date, task_id: }), stream_name: "Task$#{task_id}")
  end

  def complete_task(task_id)
    return unless find_task(task_id).status.eql?(:open)
    event_store.publish(TaskCompleted.new(data: { task_id: }), stream_name: "Task$#{task_id}")
  end

  def reopen_task(task_id)
    return unless find_task(task_id).status.eql?(:completed)
    event_store.publish(TaskReopened.new(data: { task_id: }), stream_name: "Task$#{task_id}")
  end

  def find_task(task_id)
    task = Task.new
    event_store.read.stream("Task$#{task_id}").each do |event|
      task.apply(event)
    end
    task
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
