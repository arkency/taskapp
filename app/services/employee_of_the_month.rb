# frozen_string_literal: true

class EmployeeOfTheMonth
  def call
    result = RailsEventStore::Projection
               .from_all_streams
               .init(-> { { completed_tasks_to_grab: [], employee_tasks: {} } })
               .when(TaskCompleted, ->(state, event) do
                 if state[:employee_tasks].empty?
                   state[:completed_tasks_to_grab] << event.data.fetch(:task_id)
                 end
                 state[:employee_tasks].each do |employee_id, employee_data|
                   if employee_data[:assigned_tasks].include?(event.data.fetch(:task_id))
                     employee_data[:completed_tasks] += 1
                   end
                 end
               end)
               .when(EmployeeAssignedToTask, ->(state, event) do
                 state[:employee_tasks][event.data.fetch(:employee_id)] ||= { assigned_tasks: [], completed_tasks: 0 }
                 state[:employee_tasks][event.data.fetch(:employee_id)][:assigned_tasks] << event.data.fetch(:task_id)
               end)
               .run(event_store)

    result[:completed_tasks_to_grab].each do |task_id|
      result[:employee_tasks].each do |employee_id, employee_data|
        if employee_data[:assigned_tasks].include?(task_id)
          employee_data[:completed_tasks] += 1
        end
      end
    end

    employee_id, employee_data = result[:employee_tasks].max_by { |_, data| data[:completed_tasks] }
    { employee_id: employee_id, completed_tasks: employee_data[:completed_tasks] }
  end

  private

  def event_store
    Rails.configuration.event_store
  end
end
