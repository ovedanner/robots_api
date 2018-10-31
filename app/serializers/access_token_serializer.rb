class AccessTokenSerializer < ActiveModel::Serializer
  attributes :id, :token, :created_at
  belongs_to :user
end
