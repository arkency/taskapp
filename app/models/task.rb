# frozen_string_literal: true

class Task
  include AggregateRoot

  attr_reader :name, :date, :status, :id

  def create
    apply(TaskCreated.new(data: { task_id: id }))
  end

  def initialize(id)
    @id = id
  end

  def change_name(new_name)
    @name = new_name
    return unless status.eql?(:open)
    apply(TaskNameChanged.new(data: { name: new_name, task_id: id }))
  end

  def assign_date(new_date)
    return unless status.eql?(:open)
    @date = new_date
    apply(TaskDateAssigned.new(data: { date: new_date, task_id: id }))
  end

  def complete
    return unless status.eql?(:open)
    @status = :completed
    apply(TaskCompleted.new(data: { task_id: id }))
  end

  def delete
    @status = :deleted
    apply(TaskDeleted.new(data: { task_id: id }))
  end

  def reopen
    return unless status.eql?(:completed)
    @status = :open
    apply(TaskReopened.new(data: { task_id: id }))
  end

  on TaskCreated do |event|
    @id = event.data.fetch(:task_id)
    @status = :open
  end

  on TaskNameChanged do |event|
    @name = event.data.fetch(:name)
  end

  on TaskDateAssigned do |event|
    @date = event.data.fetch(:date)

  end

  on TaskCompleted do |_|
    @status = :completed
  end

  on TaskDeleted do |_|
    @status = :deleted
  end

  on TaskReopened do |_|
    @status = :open
  end
end
