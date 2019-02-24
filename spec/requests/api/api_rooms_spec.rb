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

  describe 'GET /api/rooms/:id' do
    let(:existing_room) { FactoryBot.create(:room, owner: user) }

    context 'with valid credentials' do
      it 'will succeed' do
        get "/api/rooms/#{existing_room.id}",
            headers: auth_header(user.access_tokens.first.token)
        assert_success
      end
    end

    context 'with invalid credentials' do
      it 'will not succeed' do
        get "/api/rooms/#{existing_room.id}",
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

  describe 'GET /api/rooms/:id/members' do
    let(:room) do
      room = FactoryBot.create(:room)
      FactoryBot.create(:room_user, room: room, user: user, ready: true)
      room
    end
    let!(:member_two) { FactoryBot.create(:user_in_room, room: room) }
    let!(:member_not_ready) { FactoryBot.create(:user_in_room, room: room, ready: false) }

    context 'with valid credentials' do
      context "when user in the room" do
        it 'will succeed' do
          get "/api/rooms/#{room.id}/members",
              headers: auth_header(user.access_tokens.first.token)

          assert_success
          assert_returned_nr_records(3, 'users')

          expected_values = {
            user.id => { ready: true },
            member_two.id => { ready: true },
            member_not_ready.id => { ready: false },
          }
          assert_each_has_attributes(expected_values)
        end
      end

      context "when user is not in the room" do
        let(:other_user) do
          FactoryBot.create(:user_with_access_token)
        end

        it "will not succeed" do
          get "/api/rooms/#{room.id}/members",
              headers: auth_header(other_user.access_tokens.first.token)

          assert_not_found
        end
      end
    end
  end
end
