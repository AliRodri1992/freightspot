class CreateUserActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :user_activities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :action
      t.references :trackable, polymorphic: true, null: false
      t.string :ip_address
      t.string :city
      t.string :region
      t.string :country
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :user_agent

      t.timestamps
      t.timestamp :deleted_at
    end

    add_index :user_activities, :deleted_at
  end
end
