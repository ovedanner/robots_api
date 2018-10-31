class RoomSerializer < ActiveModel::Serializer
  attributes :id, :name, :open
  belongs_to :owner
  has_many :members, serializer: UserSerializer do
    link(:related) { "/api/rooms/#{object.id}/members" }
  end
end
