class AddLockVersionToTaskViewModel < ActiveRecord::Migration[7.1]
  def change
    add_column :task_view_models,
               :lock_version,
               :integer,
               default: 0,
               null: false
  end
end
