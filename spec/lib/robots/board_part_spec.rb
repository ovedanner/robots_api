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
          [8, 10, 9, 12, 8, 8, 8, 9],
          [0, 9, 4, 0, 0, 0, 0, 1],
          [0, 0, 0, 3, 4, 0, 0, 1],
          [0, 0, 0, 8, 0, 0, 0, 3],
          [0, 0, 0, 0, 0, 0, 0, 9],
          [0, 0, 0, 0, 1, 6, 0, 1],
          [2, 0, 2, 0, 0, 8, 0, 1],
          [15, 5, 12, 0, 0, 0, 0, 1]
        ]

        expect(part.cells).to match_array(rotated_cells)
      end
    end
  end
end
