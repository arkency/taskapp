# frozen_string_literal: true

class TaskViewModelBuilder < ActiveJob::Base
  prepend RailsEventStore::AsyncHandler

  def perform(event)
    case event
    when TaskCreated
      create_task(event)
    when TaskNameChanged
      change_task_name(event)
    when TaskDateAssigned
      assign_date(event)
    when TaskCompleted
      complete_task(event)
    when TaskDeleted
      delete_task(event)
    when TaskReopened
      reopen_task(event)
    end
  end

  private

  def event_store
    Rails.configuration.event_store
  end

  def create_task(event)
    TaskViewModel.create!(id: event.data.fetch(:task_id), status: :open)
  end

  def change_task_name(event)
    task = TaskViewModel.find(event.data.fetch(:task_id)).lock!
    if task.name_changed_at.nil? || task.name_changed_at < event.metadata[:timestamp]
      task.name_changed_at = event.metadata[:timestamp]
      task.name = event.data.fetch(:name)
    end
    task.save!
  end

  def assign_date(event)
    task = TaskViewModel.find(event.data.fetch(:task_id)).lock!
    if task.due_date_changed_at.nil? || task.due_date_changed_at < event.metadata[:timestamp]
      task.due_date_changed_at = event.metadata[:timestamp]
      task.due_date = event.data.fetch(:due_date)
    end
    task.save!
  end

  def complete_task(event)
    task = TaskViewModel.find(event.data.fetch(:task_id)).lock!
    if task.status_changed_at.nil? || task.status_changed_at < event.metadata[:timestamp]
      task.status_changed_at = event.metadata[:timestamp]
      task.status = :completed
    end
    task.save!
  end

  def delete_task(event)
    task = TaskViewModel.find(event.data.fetch(:task_id))
    task.destroy!
  rescue ActiveRecord::RecordNotFound
  end

  def reopen_task(event)
    task = TaskViewModel.find(event.data.fetch(:task_id)).lock!
    if task.status_changed_at.nil? || task.status_changed_at < event.metadata[:timestamp]
      task.status_changed_at = event.metadata[:timestamp]
      task.status = :open
    end
    task.save!
  end
end

