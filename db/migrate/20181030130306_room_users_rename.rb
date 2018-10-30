class RoomUsersRename < ActiveRecord::Migration[5.2]
  def change
    rename_table :rooms_users, :room_users
  end
end
