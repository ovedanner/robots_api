require 'rails_helper'

RSpec.describe Game, type: :model do
  # Default user and room for game tests.
  let(:user) { FactoryBot.create('user') }
  let(:room) do
    FactoryBot.create(:room_with_member, member: user, owner: user)
  end

  describe '#room' do
    it { is_expected.to validate_presence_of(:room) }
    it { is_expected.to belong_to(:room) }
  end

  describe '#board' do
    it { is_expected.to validate_presence_of(:board) }
    it { is_expected.to belong_to(:board) }
  end

  describe '#current_winner' do
    it { is_expected.to belong_to(:current_winner).optional }
  end

  describe '#robot_positions' do
    let(:valid_robot_positions) do
      <<~HEREDOC
        [{"color":"red", "position":{"row":1, "column": 2}}]
      HEREDOC
    end

    it { is_expected.to allow_value(nil).for(:robot_positions) }
    it { is_expected.not_to allow_value('invalid JSON').for(:robot_positions) }
    it { is_expected.not_to allow_value(4).for(:robot_positions) }

    it { is_expected.to allow_value(valid_robot_positions).for(:robot_positions) }
  end

  describe '#completed_goals' do
    let(:valid_completed_goals) do
      <<~HEREDOC
        [{"number": 2, "color": "red"}]
      HEREDOC
    end

    it { is_expected.to allow_value(nil).for(:completed_goals) }
    it { is_expected.not_to allow_value('invalid JSON').for(:completed_goals) }
    it { is_expected.not_to allow_value(4).for(:completed_goals) }

    it { is_expected.to allow_value(valid_completed_goals).for(:completed_goals) }
  end

  describe '#current_goal' do
    let(:valid_current_goal) do
      <<~HEREDOC
        {"number": 2, "color": "red"}
      HEREDOC
    end

    it { is_expected.to allow_value(nil).for(:current_goal) }
    it { is_expected.not_to allow_value('invalid JSON').for(:current_goal) }
    it { is_expected.not_to allow_value(4).for(:current_goal) }

    it { is_expected.to allow_value(valid_current_goal).for(:current_goal) }
  end

  describe '#start_game' do
    let(:board) do
      FactoryBot.create('board',
                        cells: [
                          [5, 1, 1, 3],
                          [8, 0, 0, 2],
                          [8, 0, 0, 2],
                          [12, 4, 4, 14]
                        ].to_json, goals: [
                          { number: 2, color: :red },
                          { number: 6, color: :blue }
                        ].to_json, robot_colors: %i[red blue].to_json)
    end

    let(:game) { FactoryBot.create('game', room: room, board: board) }

    context 'when passing in a board' do

      it 'initializes robots and the current goal' do
        game.start_game!(board)
        positions = game.parsed_robot_positions
        goal = game.parsed_current_goal

        expect(positions.length).to eq(2)
        expect(goal[:number]).to be_in([2, 6])
        expect(goal[:color]).to be_in(%w(red blue))
      end
    end
  end
end
