# Channel through which games are played.
class GameChannel < ApplicationCable::Channel
  # A user can only subscribe to the channel when he actually
  # joined the room.
  def subscribed
    @room = Room.includes(:owner).find(params[:room])
    reject unless current_user.member_of_room?(@room)
    stream_from "game:#{@room.id}"
  end

  # Whenever a user unsubscribes from the channel, he leaves the
  # room.
  def unsubscribed
    @room.remove_user(current_user)

    # Stop any pending timer.
    @moves_timer.cancel if @moves_timer&.pending?

    # If the owner leaves the channel, delete the room and the game.
    if @room.owned_by?(current_user)
      game = Game.find_by_room_id(@room.id)
      game&.destroy
      @room.destroy
    end
  end

  # The owner of the room can start a game.
  def start_new_game(message)
    if @room.owned_by?(current_user)
      # Close the room.
      @room.update!(open: false)

      # Clear any existing game.
      game = Game.find_by_room_id(@room.id)
      game&.destroy
      board = Robots::BoardGenerator.generate
      board.save

      game = Game.new(
        room: @room,
        open_for_solution: true,
        open_for_moves: false,
        board: board)

      if game.save
        game.start_game!
        data = message.merge(game.board_and_game_data)
        ActionCable.server.broadcast "game:#{@room.id}", data
      else
        logger.error("Could not create new game for room #{@room.id}")
      end
    end
  end

  # Get the next goal.
  def next_goal
    if @room.owned_by?(current_user)
      game = Game.find_by_room_id(@room.id)

      game&.evaluate do
        goal = game.next_goal!
        if goal
          # Broadcast the new goal.
          ActionCable.server.broadcast "game:#{@room.id}", action: 'new_goal', goal: goal
        else
          # The game is finished!
          ActionCable.server.broadcast "game:#{@room.id}", action: 'game_finished'
        end
      end
    end
  end

  # Called when a member has a solution in x steps.
  def solution_in(message)
    if message['nr_moves']
      nr_moves = message['nr_moves'].to_i
      game = Game.find_by_room_id(@room.id)

      game&.evaluate do
        if game.open_for_solution? &&
           game.current_best_solution?(nr_moves)

          data = {
            action: message['action'],
            current_winner: current_user.firstname,
            current_winner_id: current_user.id,
            current_nr_moves: nr_moves
          }

          # Start the game timer if it hasn't been done already.
          attributes = {
            current_nr_moves: nr_moves,
            current_winner: current_user,
            open_for_moves: true
          }
          unless game.timer_started?
            # Start the solution timer.
            @moves_timer = game.moves_timer
            game.start_solution_timer(@moves_timer)
            attributes[:timer_started] = true
          end

          game.update!(attributes)

          # Inform subscribers that someone claims to have a solution.
          ActionCable.server.broadcast "game:#{@room.id}", data
        end
      end
    end
  end

  # Actual moves are provided.
  def solution_moves(message)
    if message['moves']
      # Make sure the user providing the moves is the current
      # winner.
      moves = message['moves'].map { |m| HashWithIndifferentAccess.new(m) }
      game = Game.find_by_room_id(@room.id)

      logger.info("current winner: #{game.current_winner}, open: #{game.open_for_moves}")
      game&.evaluate do
        if game.current_winner?(current_user) && game.open_for_moves?
          logger.info("passed: #{message['moves'].length}, current: #{game.current_nr_moves}")
          if game.verify_solution!(moves)
            # Stop the moves timer if it's running.
            @moves_timer.cancel if @moves_timer&.pending?

            # Broadcast winner.
            data = {
              action: 'goal_won_by',
              winner: current_user.firstname,
              moves: message['moves']
            }
            ActionCable.server.broadcast "game:#{@room.id}", data
          end
        end
      end
    end
  end
end
