class CreateAccessTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :access_tokens do |t|
      t.integer :user_id, null: false
      t.text :token, null: false

      t.index :user_id
      t.index :token

      t.timestamps
    end
  end
end
