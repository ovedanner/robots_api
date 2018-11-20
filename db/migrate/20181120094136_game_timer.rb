class GameTimer < ActiveRecord::Migration[5.2]
  def change
    change_table :games do |t|
      t.boolean :timer_started, default: false
    end
  end
end
