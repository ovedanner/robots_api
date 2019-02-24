class UserSerializer < ActiveModel::Serializer
  attributes :id, :email, :firstname
  attribute :ready, if: :include_ready?

  def include_ready?
    scope && scope[:room].present?
  end

  def ready
    room_user = scope[:room].room_users.find do |room_user|
      room_user.user_id == object.id
    end

    room_user.ready
  end
end
