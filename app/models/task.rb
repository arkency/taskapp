# frozen_string_literal: true

class Task
  attr_reader :name, :date, :status, :id

  def initialize
    @status = :open
  end

  def change_name(new_name)
    @name = new_name
  end

  def assign_date(new_date)
    @date = new_date
  end

  def complete
    @status = :completed
  end

  def delete
    @status = :deleted
  end

  def reopen
    @status = :open
  end

  def apply(event)
    case event
    when TaskCreated
      @id = event.data.fetch(:task_id)
    when TaskNameChanged
      change_name(event.data.fetch(:name))
    when TaskDateAssigned
      assign_date(event.data.fetch(:date))
    when TaskCompleted
      complete
    when TaskDeleted
      delete
    when TaskReopened
      reopen
    end
  end
end
