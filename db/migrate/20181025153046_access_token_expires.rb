class AccessTokenExpires < ActiveRecord::Migration[5.2]
  def change
    change_table :access_tokens do |t|
      t.datetime :expires_at, null: false
    end
  end
end
