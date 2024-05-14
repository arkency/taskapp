# frozen_string_literal: true

class CompletedTasksReopened
  def for_task(task_id)
    RailsEventStore::Projection
      .from_stream("Task$#{task_id}")
      .init(-> { { completed: 0, reopened: 0 } })
      .when(TaskCompleted, ->(state, event) { state[:completed] += 1 })
      .when(TaskReopened, ->(state, event) { state[:reopened] += 1 })
      .run(event_store)
  end

  def all
    RailsEventStore::Projection
      .from_all_streams
      .init(-> { { } })
      .when(TaskReopened, ->(state, event) do
        state[event.data.fetch(:task_id)] ||= 0; state[event.data.fetch(:task_id)] += 1
      end
      )
      .run(event_store)
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
