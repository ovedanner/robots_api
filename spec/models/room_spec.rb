require 'rails_helper'

RSpec.describe Room, type: :model do
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

  describe '#add-user' do
    let(:user) { FactoryBot.create(:user) }

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
