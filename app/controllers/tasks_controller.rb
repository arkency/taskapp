class TasksController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    event_store.with_metadata({ user_id: 1, tenant_id: 1234 }) do
      uuid = TaskService.new.create_task
      render json: { uuid: uuid }
    end
  end

  def change_name
    event_store.with_metadata({ user_id: 1, tenant_id: 1234 }) do
      TaskService.new.change_name(params[:id], params[:name])
    end
    render plain: "Task name changed"
  end

  def complete_task
    event_store.with_metadata({ user_id: 1, tenant_id: 1234 }) do
      TaskService.new.complete_task(params[:id])
    end
    render plain: "Task completed"
  end

  def reopen_task
    event_store.with_metadata({ user_id: 1, tenant_id: 1234 }) do
      TaskService.new.reopen_task(params[:id])
    end
    render plain: "Task reopened"
  end

  def delete
    event_store.with_metadata({ user_id: 1, tenant_id: 1234 }) do
      TaskService.new.delete_task(params[:id])
    end
    render plain: "Task deleted"
  end

  def assign_date
    event_store.with_metadata({ user_id: 1, tenant_id: 1234 }) do
      TaskService.new.assign_date(params[:id], params[:date])
    end
    render plain: "Task date assigned"
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
