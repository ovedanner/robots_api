class RoomUsersRename < ActiveRecord::Migration[5.2]
  def change
    rename_table :rooms_users, :room_users

    change_table :room_users do |t|
      t.boolean :ready, default: false
    end
  end
end
