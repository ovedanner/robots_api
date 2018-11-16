class UpdateGame < ActiveRecord::Migration[5.2]
  def change
    change_table :games do |t|
      t.json :robot_positions, null: true
      t.json :completed_goals, null: true
      t.json :current_goal, null: true
      t.boolean :open_for_solution, default: false
      t.boolean :open_for_moves, default: false
      t.integer :current_nr_moves, null: true
      t.belongs_to :user, column: :current_winner_id, foreign_key: true
    end
  end
end
