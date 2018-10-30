require 'rails_helper'

RSpec.describe Room, type: :model do
  describe '#owner' do
    it { is_expected.to validate_presence_of(:owner) }
    it { is_expected.to belong_to(:owner) }
  end

  describe '#room_users' do
    it { is_expected.to have_many(:room_user) }
  end

  describe '#board' do
    let(:valid_board) do
      <<~HEREDOC
        {"cells":[[1,1,1],[2,2,2],[3,3,3]],"goals":[{"number":2,"color":"red"}],"robot_colors":["red"]}
      HEREDOC
    end

    it { is_expected.to allow_value(nil).for(:board) }
    it { is_expected.not_to allow_value('invalid JSON').for(:board) }
    it { is_expected.not_to allow_value(4).for(:board) }

    it { is_expected.to allow_value(valid_board).for(:board) }
  end

  describe '#open' do
    it { is_expected.to allow_value(true).for(:open) }
    it { is_expected.to allow_value(false).for(:open) }
  end
end
