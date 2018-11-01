class RoomSerializer < ActiveModel::Serializer
  attributes :id, :name, :open
  belongs_to :owner

  has_many :members, serializer: UserSerializer do
    link(:related) { "/api/rooms/#{object.id}/members" }
    include_data false
    members = object.members

    # Needed to avoid N+1 queries, see
    # https://github.com/rails-api/active_model_serializers/issues/1325
    members.loaded? ? members : members.none
  end
end
