# Represents a room users can join.
class Room < ApplicationRecord
  belongs_to :owner, class_name: 'User', foreign_key: :owner_id
  has_many :room_users, dependent: :destroy
  has_many :members,
           through: :room_users,
           source: :user,
           dependent: :destroy
  has_one :game, dependent: :destroy

  validates :owner, presence: true
  validates_inclusion_of :open, in: [true, false]

  # Whether or not the room is owned by the given user.
  def owned_by?(user)
    owner.id == user.id
  end

  # Returns whether or not all the members in the room are ready.
  def all_users_ready?
    nr_members = members.size
    nr_ready = RoomUser.where(room_id: id, ready: true).count
    nr_members > 0 && nr_ready == nr_members
  end

  # Indicates that all users are ready.
  def all_users_ready!
    RoomUser.where(room_id: id).update_all(ready: true)
  end

  # Indicates that no users are ready.
  def no_users_ready!
    RoomUser.where(room_id: id).update_all(ready: false)
  end

  # Indicates that the given user is ready to play.
  def user_ready!(user)
    room_user = RoomUser.where(room_id: id, user_id: user.id).first
    if room_user
      room_user.ready = true
      room_user.save!
    end
  end

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
