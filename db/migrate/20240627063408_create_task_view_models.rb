class CreateTaskViewModels < ActiveRecord::Migration[7.1]
  def change
    create_table :task_view_models, id: :uuid do |t|
      t.string :name
      t.datetime :due_date
      t.string :status

      t.timestamps
    end

  end
end
