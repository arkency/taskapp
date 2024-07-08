# frozen_string_literal: true

class TaskViewModelBuilder < EventHandler
  def call(event)
    task_id = event.data.fetch(:task_id)
    ApplicationRecord.with_advisory_lock("task_view_model_#{task_id}") do
      task_view_model = TaskViewModel.find_by(id: task_id) || TaskViewModel.new(id: task_id)
      checkpoint = task_view_model.checkpoint

      task_stream = event_store.read.stream("Task$#{task_id}")
      task_stream = task_stream.from(checkpoint) if checkpoint

      task_stream.each do |event|
        case event
        when TaskCreated
          create_task(event, task_view_model)
        when TaskNameChanged
          change_task_name(event, task_view_model)
        when TaskDateAssigned
          assign_date(event, task_view_model)
        when TaskCompleted
          complete_task(event, task_view_model)
        when TaskDeleted
          delete_task(event, task_view_model)
        when TaskReopened
          reopen_task(event, task_view_model)
        end

        task_view_model.checkpoint = event.event_id
      end

      task_view_model.save!
    end
  end

  private

  def event_store
    Rails.configuration.event_store
  end

  def create_task(_event, task)
    task.status = :open
  end

  def change_task_name(event, task)
    name = event.data.fetch(:name)
    task.name = name
  end

  def assign_date(event, task)
    task.due_date = event.data.fetch(:due_date)
  end

  def complete_task(_event, task)
    task.status = :completed
  end

  def delete_task(_event, task)
    task.destroy!
  rescue ActiveRecord::RecordNotFound
  end

  def reopen_task(_event, task)
    task.status = :open
  end
end

