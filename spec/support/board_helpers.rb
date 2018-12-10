module BoardHelpers
  # Validates board response data.
  def assert_valid_board_data(data)
    cells, goals, robot_colors = data.values_at(:cells, :goals, :robot_colors)

    # Validate the number of rows and columns.
    expect(cells.length).to eq(16)
    cells.each_with_index do |row, idx|
      expect(row.length).to eq(16)

      # The middle cells should have all walls.
      expect(row[7]).to eq(15) if [7, 8].include?(idx)
      expect(row[8]).to eq(15) if [7, 8].include?(idx)
    end

    expect(goals.length).to eq(17)
    expect(robot_colors.length).to eq(5)
  end

  def indifferent_hash(h)
    HashWithIndifferentAccess.new(h)
  end

  def indifferent_array(arr)
    result = []
    arr.each do |el|
      result << if el.is_a?(Hash)
        HashWithIndifferentAccess.new(el)
      else
        el
                end
    end
    result
  end
end

RSpec.configure do |config|
  config.include BoardHelpers
end
