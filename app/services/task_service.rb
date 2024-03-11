# frozen_string_literal: true

class TaskService

  def create_task
    uuid = SecureRandom.uuid
    event_store.publish(TaskCreated.new, stream_name: "Task$#{uuid}")
    uuid
  end

  def change_name(task_id, new_name)
    event_store.publish(TaskNameChanged.new(data: { name: new_name }), stream_name: "Task$#{task_id}")
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
