# Let the Robots module use the same logger as rails.
module Robots
  def self.logger
    @logger ||= Rails.logger
  end
end
