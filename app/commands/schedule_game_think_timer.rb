# Schedules a timer that closes the current round
# after a certain number of seconds so the winner
# can provide his moves.
#
class ScheduleGameThinkTimer
  prepend SimpleCommand

  attr_accessor :game

  def initialize(game)
    @game = game
  end

  def call()
    Rails.application.executor.wrap do
      Concurrent::ScheduledTask.execute(Game::THINK_TIMEOUT) do
        @game.solve_lock.lock do
          @game.close_for_solution!
          schedule_move_timeout
        end
      end
    end
  end

  def schedule_move_timeout
    Rails.application.executor.wrap do
      Concurrent::ScheduledTask.execute(Game::MOVE_TIMEOUT) do
        @game.close_for_moves!
      end
    end
  end
end
