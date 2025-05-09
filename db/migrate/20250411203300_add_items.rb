class AddItems < ActiveRecord::Migration[7.0]
  def change
    create_table :items do |t|
      t.string :title
      t.string :description
      t.boolean :completed, default: false

      t.references :todo_list, null: false, foreign_key: true
      t.timestamps
    end
  end
end
