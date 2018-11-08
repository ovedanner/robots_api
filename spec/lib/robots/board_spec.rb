require 'rails_helper'

RSpec.describe Robots::Board do
  describe '#column_cells' do
    let(:board) do
      Robots::Board.new(
        [
          [1, 2, 3, 4],
          [5, 6, 7, 8],
          [9, 10, 11, 12],
          [13, 14, 15, 0]
        ], [
          { number: 2, color: :red }
        ], [:red]
      )
    end

    context 'when retrieving column cells' do
      it 'returns the proper array' do
        expected = [
          [1, 5, 9, 13],
          [2, 6, 10, 14],
          [3, 7, 11, 15],
          [4, 8, 12, 0]
        ]
        expect(board.column_cells).to match_array(expected)
      end
    end
  end

  describe '.valid_move?' do
    let(:board) do
      Robots::Board.new(
        [
          [5, 1, 1, 3],
          [8, 0, 0, 2],
          [8, 0, 0, 2],
          [12, 4, 4, 6]
        ], [
          { number: 2, color: :red },
          { number: 6, color: :blue }
        ], %i[red blue]
      )
    end

    let(:robot_positions) do
      [
        {robot: :red, position: {row: 1, column: 1 } },
        {robot: :blue, position: {row: 3, column: 1 } }
      ]
    end

    context 'when valid up move' do
      let(:move) do
        {
          robot: :red,
          to: {
            row: 0,
            column: 1
          }
        }
      end

      it 'returns true' do
        result = Robots::Board.valid_move?(board, move, robot_positions)
        expect(result).to eq(true)
      end
    end

    context 'when diagonal up move' do
      let(:move) do
        {
          robot: :red,
          to: {
            row: 0,
            column: 0
          }
        }
      end

      it 'returns false' do
        result = Robots::Board.valid_move?(board, move, robot_positions)
        expect(result).to eq(false)
      end
    end

    context 'when valid down move' do
      let(:move) do
        {
          robot: :red,
          to: {
            row: 2,
            column: 1
          }
        }
      end

      it 'returns true' do
        result = Robots::Board.valid_move?(board, move, robot_positions)
        expect(result).to eq(true)
      end
    end

    context 'when diagonal down move' do
      let(:move) do
        {
          robot: :red,
          to: {
            row: 2,
            column: 2
          }
        }
      end

      it 'returns false' do
        result = Robots::Board.valid_move?(board, move, robot_positions)
        expect(result).to eq(false)
      end
    end

    context 'when down to robot move' do
      let(:move) do
        {
          robot: :red,
          to: {
            row: 3,
            column: 1
          }
        }
      end

      it 'returns false' do
        result = Robots::Board.valid_move?(board, move, robot_positions)
        expect(result).to eq(false)
      end
    end

    context 'when valid left move' do
      let(:move) do
        {
          robot: :red,
          to: {
            row: 1,
            column: 0
          }
        }
      end

      it 'returns true' do
        result = Robots::Board.valid_move?(board, move, robot_positions)
        expect(result).to eq(true)
      end
    end

    context 'when valid right move' do
      let(:move) do
        {
          robot: :red,
          to: {
            row: 1,
            column: 3
          }
        }
      end

      it 'returns true' do
        result = Robots::Board.valid_move?(board, move, robot_positions)
        expect(result).to eq(true)
      end
    end

    context 'when invalid right move through wall' do
      let(:move) do
        {
          robot: :blue,
          to: {
            row: 3,
            column: 3
          }
        }
      end

      it 'returns true' do
        result = Robots::Board.valid_move?(board, move, robot_positions)
        expect(result).to eq(false)
      end
    end
  end
end
