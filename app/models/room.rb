# Represents a room users can join.
class Room < ApplicationRecord
  belongs_to :owner, class_name: 'User', foreign_key: :owner_id
  has_many :room_users, dependent: :destroy
  has_many :members,
           class_name: 'User',
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

  # Starts a new game in the room.
  def start_new_game!
    # Close the room.
    update!(open: false)

    # Clear any existing game.
    game = Game.find_by_room_id(id)
    game&.destroy

    # Generate a new board.
    board = Robots::BoardGenerator.generate
    board.save

    # Create a new game and broadcast game and
    # board data to the users.
    game = Game.new(
      room: self,
      open_for_solution: true,
      open_for_moves: false,
      board: board)
    if game.save
      game.start_game!
      data = { action: 'start_new_game' }.merge(game.board_and_game_data)
      ActionCable.server.broadcast "game:#{id}", data
    else
      logger.error("Could not create new game for room #{id}")
    end
  end
end
