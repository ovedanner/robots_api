require 'rails_helper'

RSpec.describe 'Api::Rooms', type: :request do
  let(:user) do
    FactoryBot.create(:user_with_access_token, email: 'guy@test.com', password: 'Safe1234')
  end

  describe 'POST /api/rooms' do
    let(:room_data) do
      {
        data: {
          type: 'rooms',
          attributes: {
            name: 'Some Room'
          }
        }
      }
    end

    context 'with valid credentials' do
      it 'will succeed' do
        post '/api/rooms', params: room_data,
                           headers: auth_header(user.access_tokens.first.token)
        assert_created
      end
    end

    context 'with invalid credentials' do
      it 'will not succeed' do
        post '/api/rooms', params: room_data,
                           headers: auth_header('bogustoken')
        assert_unauthorized
      end
    end
  end

  describe 'PATCH /api/rooms/:id' do
    let(:existing_room) { FactoryBot.create(:room, owner: user) }
    let(:room_data) do
      {
        data: {
          type: 'rooms',
          attributes: {
            name: 'Derpy'
          }
        }
      }
    end

    context 'with valid credentials' do
      it 'will succeed' do
        patch "/api/rooms/#{existing_room.id}",
              params: room_data,
              headers: auth_header(user.access_tokens.first.token)
        assert_success
        room = Room.find(existing_room.id)
        expect(room.name).to eq(room_data[:data][:attributes][:name])
      end
    end

    context 'with invalid credentials' do
      it 'will not succeed' do
        patch "/api/rooms/#{existing_room.id}",
              params: room_data,
              headers: auth_header('bogustoken')
        assert_unauthorized
      end
    end
  end

  describe 'DELETE /api/rooms/:id' do
    let(:own_room) { FactoryBot.create(:room, owner: user) }
    let(:other_room) do
      other_user = FactoryBot.create(:user)
      FactoryBot.create(:room, owner: other_user)
    end

    context 'with valid credentials' do
      it 'will succeed if own room' do
        delete "/api/rooms/#{own_room.id}",
               headers: auth_header(user.access_tokens.first.token)
        assert_success
      end

      it 'will fail if not own room' do
        delete "/api/rooms/#{other_room.id}",
               headers: auth_header(user.access_tokens.first.token)
        assert_not_found
      end
    end

    context 'with invalid credentials' do
      it 'will not succeed' do
        delete "/api/rooms/#{own_room.id}",
               headers: auth_header('doesnotexist')
        assert_unauthorized
      end
    end
  end

  describe 'POST /api/rooms/:id/join' do
    context 'with valid credentials and open room' do
      let(:open_room) { FactoryBot.create(:open_room) }

      it 'will succeed' do
        post "/api/rooms/#{open_room.id}/join",
             headers: auth_header(user.access_tokens.first.token)
        assert_success
      end
    end

    context 'with valid credentials and closed room' do
      let(:closed_room) { FactoryBot.create(:closed_room) }

      it 'will succeed' do
        post "/api/rooms/#{closed_room.id}/join",
             headers: auth_header(user.access_tokens.first.token)
        assert_not_found
      end
    end
  end
end
