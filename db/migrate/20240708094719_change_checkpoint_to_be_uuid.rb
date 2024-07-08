class ChangeCheckpointToBeUuid < ActiveRecord::Migration[7.1]
  def change
    remove_column :task_view_models, :checkpoint
    add_column :task_view_models, :checkpoint, :uuid
  end
end
