class AddChangedAtColumnsToTaskViewModel < ActiveRecord::Migration[7.1]
  def change
    add_column :task_view_models, :name_changed_at, :datetime
    add_column :task_view_models, :due_date_changed_at, :datetime
    add_column :task_view_models, :status_changed_at, :datetime
  end
end
