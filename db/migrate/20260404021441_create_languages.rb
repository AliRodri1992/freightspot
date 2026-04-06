class CreateLanguages < ActiveRecord::Migration[8.0]
  def change
    create_table :languages do |t|
      t.string :name
      t.string :code

      t.timestamps
      t.timestamp :deleted_at
    end

    add_index :languages, :deleted_at

    add_index :languages, :name, unique: true
    add_index :languages, :code, unique: true
  end
end
