require 'rails_helper'

RSpec.describe Room, type: :model do
  let(:user) { FactoryBot.create(:user) }

  describe '#owner' do
    it { is_expected.to validate_presence_of(:owner) }
    it { is_expected.to belong_to(:owner) }
  end

  describe '#room_users' do
    it { is_expected.to have_many(:room_users) }
  end

  describe '#members' do
    it { is_expected.to have_many(:members) }
  end

  describe '#open' do
    it { is_expected.to allow_value(true).for(:open) }
    it { is_expected.to allow_value(false).for(:open) }
  end

  describe '#user_ready!' do
    context 'when user not ready yet' do
      let(:room) { FactoryBot.create(:room_with_member, member: user) }

      it 'marks the user as ready' do
        room.user_ready!(user)
        room_user = RoomUser.where(user: user).first
        expect(room_user.ready).to eq(true)
      end
    end
  end

  describe '#all_users_ready?' do
    let(:room) { FactoryBot.create('room') }

    context 'when all users ready' do
      let!(:user_one) do
        user = FactoryBot.create('user')
        FactoryBot.create(:room_user, user_id: user.id, room_id: room.id, ready: true)
        user
      end

      let!(:user_two) do
        user = FactoryBot.create('user')
        FactoryBot.create(:room_user, user_id: user.id, room_id: room.id, ready: true)
        user
      end

      it 'returns true' do
        expect(room.all_users_ready?).to eq(true)
      end
    end

    context 'when not all users ready' do
      let!(:user_one) do
        user = FactoryBot.create('user')
        FactoryBot.create(:room_user, user_id: user.id, room_id: room.id, ready: true)
        user
      end

      let!(:user_two) do
        user = FactoryBot.create('user')
        FactoryBot.create(:room_user, user_id: user.id, room_id: room.id, ready: false)
        user
      end

      it 'returns false' do
        expect(room.all_users_ready?).to eq(false)
      end
    end
  end

  describe '#all_users_ready!' do
    let(:room) { FactoryBot.create('room') }

    let!(:user_one) do
      user = FactoryBot.create('user')
      FactoryBot.create(:room_user, user_id: user.id, room_id: room.id, ready: false)
      user
    end

    let!(:user_two) do
      user = FactoryBot.create('user')
      FactoryBot.create(:room_user, user_id: user.id, room_id: room.id, ready: false)
      user
    end

    context 'when users not ready yet' do
      it 'marks the users as ready' do
        room.all_users_ready!
        room_users = RoomUser.where(room_id: room.id)
        expect(room_users.length).to eq(2)
        room_users.each do |r_user|
          expect(r_user.ready).to eq(true)
        end
      end
    end
  end

  describe '#no_users_ready!' do
    let(:room) { FactoryBot.create('room') }

    let!(:user_one) do
      user = FactoryBot.create('user')
      FactoryBot.create(:room_user, user_id: user.id, room_id: room.id, ready: true)
      user
    end

    let!(:user_two) do
      user = FactoryBot.create('user')
      FactoryBot.create(:room_user, user_id: user.id, room_id: room.id, ready: true)
      user
    end

    context 'when users ready' do
      it 'marks the users as not ready' do
        room.no_users_ready!
        room_users = RoomUser.where(room_id: room.id)
        expect(room_users.length).to eq(2)
        room_users.each do |r_user|
          expect(r_user.ready).to eq(false)
        end
      end
    end
  end

  describe '#add_user' do
    context 'when room is open and user not in room' do
      let(:open_room) { FactoryBot.create(:room, open: true) }

      it 'will succeed' do
        expect(open_room.add_user(user)).to eq(true)
        expect(open_room.members.length).to be(1)
        expect(open_room.members[0].id).to eq(user.id)
      end
    end

    context 'when room is open and user in room' do
      let(:open_room) do
        FactoryBot.create(:room_with_member, member: user, open: true)
      end

      it 'will succeed' do
        expect(open_room.add_user(user)).to eq(true)
        expect(open_room.members.length).to be(1)
        expect(open_room.members[0].id).to eq(user.id)
      end
    end

    context 'when room is closed' do
      let(:closed_room) { FactoryBot.create(:closed_room) }

      it 'will fail' do
        expect(closed_room.add_user(user)).to eq(false)
        expect(closed_room.members.length).to be(0)
      end
    end
  end

  describe '#remove_user' do
    let(:user) { FactoryBot.create(:user) }

    context 'when user is in room' do
      let(:room) do
        FactoryBot.create(:room_with_member, member: user)
      end

      it 'will succeed' do
        expect(room.remove_user(user)).to eq(true)
      end
    end
  end
end
