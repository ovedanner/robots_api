class GameTimer < ActiveRecord::Migration[5.2]
  def change
    change_table :games do |t|
      t.string :timer, default: nil
    end
  end
end
