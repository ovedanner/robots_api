# Holds room members.
class RoomUser < ApplicationRecord
  belongs_to :user
  belongs_to :room

  validates :user, presence: true
  validates :room, presence: true

  scope :ready, -> { where(ready: true) }
end
