class CreateRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :roles do |t|
      t.string :name

      t.timestamps
      t.timestamp :deleted_at
    end
    add_index :roles, :name, unique: true
    add_index :roles, :deleted_at
  end
end
