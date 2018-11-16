class CreateBoards < ActiveRecord::Migration[5.2]
  def change
    create_table :boards do |t|
      t.json :cells, null: false
      t.json :goals, null: false
      t.json :robot_colors, null: false
      t.timestamps
    end

    change_table :games do |t|
      t.belongs_to :board, foreign_key: true
    end
  end
end
