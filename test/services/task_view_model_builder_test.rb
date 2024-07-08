# frozen_string_literal: true

require_relative "../test_helper"

class TaskViewModelBuilderTest < ActiveSupport::TestCase
  def test_builds_the_read_model
    task_id = SecureRandom.uuid
    builder = TaskViewModelBuilder.new
    builder.call(TaskCreated.new(data: { task_id: }))
    builder.call(TaskNameChanged.new(data: { task_id:, name: "Name" }))
    builder.call(TaskDateAssigned.new(data: { task_id:, due_date: Date.new(2020, 1, 1) }))
    builder.call(TaskNameChanged.new(data: { task_id:, name: "New name" }))
    builder.call(TaskCompleted.new(data: { task_id: }))

    TaskViewModel.find(task_id).tap do |task|
      assert_equal "New name", task.name
      assert_equal Date.new(2020, 1, 1), task.due_date
      assert_equal "completed", task.status
    end
  end

  def test_respects_order
    task_id = SecureRandom.uuid
    first_name_change = TaskNameChanged.new(data: { task_id:, name: "New name" }, metadata: { timestamp: Time.now - 1.minute })
    second_name_change = TaskNameChanged.new(data: { task_id:, name: "Meh new name" }, metadata: { timestamp: Time.now })
    builder = TaskViewModelBuilder.new
    builder.call(TaskCreated.new(data: { task_id: }))
    builder.call(second_name_change)
    builder.call(first_name_change)

    TaskViewModel.find(task_id).tap do |task|
      assert_equal "Meh new name", task.name
    end
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end

