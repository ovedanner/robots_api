require 'rails_helper'

RSpec.describe Robots::BoardPart do
  describe '#rotate_90!' do
    let(:part) do
      Robots::BoardPart.new(
        [
          [9, 1, 1, 3, 9, 1, 1, 1],
          [8, 0, 0, 0, 0, 0, 0, 0],
          [8, 0, 0, 0, 0, 6, 8, 0],
          [8, 0, 4, 0, 0, 1, 0, 0],
          [12, 0, 3, 8, 0, 0, 0, 0],
          [9, 4, 0, 0, 0, 0, 2, 12],
          [10, 9, 0, 0, 0, 0, 0, 5],
          [8, 0, 0, 0, 0, 0, 2, 15]
        ],
        [
          { number: 21, color: :blue },
          { number: 34, color: :green },
          { number: 47, color: :red },
          { number: 49, color: :yellow }
        ],
        Robots::BoardPart::RED_GEAR,
        Robots::BoardPart::P_1
      )
    end

    context 'when rotating once' do
      it 'properly transposes' do
        part.rotate_90!(1)
        rotated_cells = [
          [1, 5, 3, 9, 1, 1, 1, 3],
          [0, 3, 8, 0, 0, 0, 0, 2],
          [0, 0, 0, 6, 8, 0, 0, 2],
          [0, 0, 0, 1, 0, 0, 0, 6],
          [0, 0, 0, 0, 0, 0, 0, 3],
          [0, 0, 0, 0, 2, 12, 0, 2],
          [4, 0, 4, 0, 0, 1, 0, 2],
          [15, 10, 9, 0, 0, 0, 0, 2]
        ]
        rotated_goals = [
          { number: 45, color: :blue },
          { number: 19, color: :green },
          { number: 58, color: :red },
          { number: 9, color: :yellow }
        ]

        expect(part.cells).to match_array(rotated_cells)
        expect(part.goals).to match_array(rotated_goals)
      end
    end
  end

  describe '.rotate_walls_90' do
    context 'when rotating single walls' do
      it 'returns the proper walls' do
        expect(Robots::BoardPart.rotate_walls_90(1)).to eq(2)
        expect(Robots::BoardPart.rotate_walls_90(2)).to eq(4)
        expect(Robots::BoardPart.rotate_walls_90(4)).to eq(8)
        expect(Robots::BoardPart.rotate_walls_90(8)).to eq(1)
      end
    end

    context 'when rotating double walls' do
      it 'returns the proper walls' do
        expect(Robots::BoardPart.rotate_walls_90(3)).to eq(6)
        expect(Robots::BoardPart.rotate_walls_90(6)).to eq(12)
        expect(Robots::BoardPart.rotate_walls_90(12)).to eq(9)
        expect(Robots::BoardPart.rotate_walls_90(9)).to eq(3)

        expect(Robots::BoardPart.rotate_walls_90(5)).to eq(10)
        expect(Robots::BoardPart.rotate_walls_90(10)).to eq(5)
      end
    end

    context 'when rotating triple walls' do
      it 'returns the proper walls' do
        expect(Robots::BoardPart.rotate_walls_90(7)).to eq(14)
        expect(Robots::BoardPart.rotate_walls_90(14)).to eq(13)
        expect(Robots::BoardPart.rotate_walls_90(13)).to eq(11)
      end
    end
  end
end
