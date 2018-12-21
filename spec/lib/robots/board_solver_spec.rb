require 'rails_helper'

RSpec.describe Robots::BoardSolver do
  let(:board) do
    FactoryBot.create(
      'board',
      cells: [
        [9, 1, 3],
        [8, 0, 2],
        [12, 4, 6]
      ], goals: [
        { number: 0, color: Board::RED },
      ], robot_colors: [Board::RED]
    )
  end
  let(:goal) { { number: 0, color: Board::RED } }
  let(:solver) { described_class.new(board) }

  describe '#up' do
    let(:robot_positions) do
      [{ robot: Board::RED, position: { row: 2, column: 2 }}]
    end

    context 'when robot can move up' do
      it 'moves to the proper location' do
        new_positions = solver.up(Board::RED, robot_positions)
        expect(new_positions).to match_array([{ robot: Board::RED, position: { row: 0, column: 2 }}])
      end
    end
  end

  describe '#down' do
    let(:robot_positions) do
      [{ robot: Board::RED, position: { row: 0, column: 1 }}]
    end

    context 'when robot can move down' do
      it 'moves to the proper location' do
        new_positions = solver.down(Board::RED, robot_positions)
        expect(new_positions).to match_array([{ robot: Board::RED, position: { row: 2, column: 1 }}])
      end
    end
  end

  describe '#left' do
    let(:robot_positions) do
      [{ robot: Board::RED, position: { row: 1, column: 2 }}]
    end

    context 'when robot can move left' do
      it 'moves to the proper location' do
        new_positions = solver.left(Board::RED, robot_positions)
        expect(new_positions).to match_array([{ robot: Board::RED, position: { row: 1, column: 0 }}])
      end
    end
  end

  describe '#right' do
    let(:robot_positions) do
      [{ robot: Board::RED, position: { row: 2, column: 0 }}]
    end

    context 'when robot can move right' do
      it 'moves to the proper location' do
        new_positions = solver.right(Board::RED, robot_positions)
        expect(new_positions).to match_array([{ robot: Board::RED, position: { row: 2, column: 2 }}])
      end
    end
  end

  describe '#solve' do
    let(:board) do
      FactoryBot.create(
        'board',
        cells: [
          [9, 1, 3, 1, 3],
          [8, 0, 0, 0, 2],
          [8, 1, 0, 15, 2],
          [8, 0, 0, 0, 2],
          [12, 4, 4, 6, 6],
        ], goals: [
          { number: 2, color: Board::RED },
        ], robot_colors: [Board::RED, Board::BLUE, Board::YELLOW]
      )
    end
    let(:robot_positions) do
      [
        { robot: Board::RED, position: { row: 3, column: 1 }},
        { robot: Board::BLUE, position: { row: 2, column: 0 }},
        { robot: Board::YELLOW, position: { row: 1, column: 3 }},
      ]
    end

    it 'generates proper moves' do
      solver = described_class.new(board)
      solver.solve(robot_positions, board.goals[0])
      expect(solver.candidate).to be_truthy
    end
  end
end
