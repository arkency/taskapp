class AddCheckpointToTaskViewModel < ActiveRecord::Migration[7.1]
  def change
    add_column :task_view_models, :checkpoint, :string
  end
end
