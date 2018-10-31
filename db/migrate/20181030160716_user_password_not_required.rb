class UserPasswordNotRequired < ActiveRecord::Migration[5.2]
  def change
    change_table :users do
      change_column_null :users, :password_digest, true
    end
  end
end
