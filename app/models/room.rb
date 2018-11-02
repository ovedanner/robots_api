# Represents a room users can join.
class Room < ApplicationRecord
  belongs_to :owner, class_name: 'User', foreign_key: :owner_id
  has_many :room_users
  has_many :members, class_name: 'User', through: :room_users, source: :user

  validates :owner, presence: true
  validates :board, json: true, allow_blank: true
  validates_inclusion_of :open, in: [true, false]

  # Adds the given user to the room if possible.
  # If he is already in the room, consider it a success
  # as well.
  def add_user(user)
    params = { room_id: id, user_id: user.id }
    if open
      RoomUser.create(params) unless RoomUser.exists?(params)
      true
    else
      false
    end
  end

  # Removes the given user from the given room. If
  # the user is not in the room, consider it a success
  # as well.
  def remove_user(user)
    room_user = RoomUser.where(room_id: id, user_id: user.id).first
    if room_user&.destroy
      true
    else
      false
    end
  end
end
