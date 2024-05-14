# frozen_string_literal: true

class EmployeeOfTheMonth
  def call
    result = RailsEventStore::Projection
               .from_all_streams
               .init(-> { {} })
               .when(TaskCompleted, ->(state, event) do
                 state.each do |employee_id, employee_data|
                   if employee_data[:assigned_tasks].include?(event.data.fetch(:task_id))
                     employee_data[:completed_tasks] += 1
                   end
                 end
               end)
               .when(EmployeeAssignedToTask, ->(state, event) do
                 state[event.data.fetch(:employee_id)] ||= { assigned_tasks: [], completed_tasks: 0 }
                 state[event.data.fetch(:employee_id)][:assigned_tasks] << event.data.fetch(:task_id)
               end)
               .run(event_store)

    employee_id, employee_data = result.max_by { |_, data| data[:completed_tasks] }
    { employee_id: employee_id, completed_tasks: employee_data[:completed_tasks] }
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
