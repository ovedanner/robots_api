class RoomSerializer < ActiveModel::Serializer
  attributes :id, :name, :open
  belongs_to :owner, key: :owner_id
end
