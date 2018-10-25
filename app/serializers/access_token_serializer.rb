class AccessTokenSerializer < ActiveModel::Serializer
  attributes :id, :token, :created_at
end
