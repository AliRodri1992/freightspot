class AddUniqueSessionIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :unique_session_id, :string
    add_index :users, :unique_session_id
  end
end
