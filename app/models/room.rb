# Represents a room users can join.
class Room < ApplicationRecord
  belongs_to :owner, class_name: 'User', foreign_key: :owner_id
  has_many :room_users
  has_many :members, class_name: 'User', through: :room_users, source: :user

  validates :owner, presence: true
  validates :board, json: true, allow_blank: true
  validates_inclusion_of :open, in: [true, false]

  # Adds the given user to the given room if possible.
  # If he is already in the room, consider it a success
  # as well.
  def self.add_user(room_id, user_id)
    room = find(room_id)
    params = { room_id: room_id, user_id: user_id }
    if room&.open
      RoomUser.create(params) unless RoomUser.exists?(params)
      true
    else
      false
    end
  end

  # Removes the given user from the given room.
  def self.remove_user(room_id, user_id)
    room_user = RoomUser.where(room_id: room_id, user_id: user_id)
    room_user&.destroy
  end
end
