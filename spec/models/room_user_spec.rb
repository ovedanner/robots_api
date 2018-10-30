require 'rails_helper'

RSpec.describe RoomUser, type: :model do
  describe '#room' do
    it { is_expected.to validate_presence_of(:room) }
    it { is_expected.to belong_to(:room) }
  end

  describe '#user' do
    it { is_expected.to validate_presence_of(:user) }
    it { is_expected.to belong_to(:user) }
  end
end
