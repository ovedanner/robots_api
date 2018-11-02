class PrimaryKeyForRoomUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :room_users, :id, :primary_key
  end
end
