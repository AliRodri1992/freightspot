class CreateTranslates < ActiveRecord::Migration[8.0]
  def change
    create_table :translates do |t|
      t.string :key
      t.text :value
      t.references :language, null: false, foreign_key: true
      t.string :controller
      t.string :view
      t.string :status, default: 'pending'

      t.timestamps
      t.timestamp :deleted_at
    end

    add_index :translates, [:key, :language_id], unique: true
    add_index :translates, :deleted_at
  end
end
