class RoomName < ActiveRecord::Migration[5.2]
  def change
    change_table :rooms do |t|
      t.string :name, null: false
    end
  end
end
