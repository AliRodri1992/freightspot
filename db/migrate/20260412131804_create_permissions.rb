class CreatePermissions < ActiveRecord::Migration[8.0]
  def change
    create_table :permissions do |t|
      t.string :name

      t.timestamps
      t.timestamp :deleted_at
    end

    add_index :permissions, :name, unique: true
    add_index :permissions, :deleted_at
  end
end
