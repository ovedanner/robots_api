class AddPasswordDigestForUsers < ActiveRecord::Migration[5.2]
  def change
    change_table :users do |t|
      change_column_null :users, :email, false
      change_column_null :users, :firstname, false
      t.string :password_digest, null: false
    end
  end
end
