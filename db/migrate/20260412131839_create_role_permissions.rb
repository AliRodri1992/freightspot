class CreateRolePermissions < ActiveRecord::Migration[8.0]
  def change
    create_table :role_permissions do |t|
      t.references :role, null: false, foreign_key: true
      t.references :permission, null: false, foreign_key: true

      t.timestamps
      t.timestamp :deleted_at
    end

    add_index :role_permissions, [:role_id, :permission_id], unique: true
    add_index :role_permissions, :deleted_at
  end
end
