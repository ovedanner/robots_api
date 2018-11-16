class RenameGameWinnerReference < ActiveRecord::Migration[5.2]
  def change
    rename_column :games, :user_id, :current_winner_id
  end
end
