class CreateProjects < ActiveRecord::Migration[7.1]
  def change
    create_table :projects do |t|
      t.string :name
      t.text :description
      t.string :status
      t.string :priority
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end
