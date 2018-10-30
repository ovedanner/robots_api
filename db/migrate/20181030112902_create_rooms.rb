class CreateRooms < ActiveRecord::Migration[5.2]
  def change
    create_table :rooms do |t|
      t.integer :owner_id, null: false
      t.json :board, null: true
      t.boolean :open, default: false

      t.timestamps
    end

    create_join_table :users, :rooms
  end
end
