class AddConfirmableToPlayers < ActiveRecord::Migration[8.0]
  def change
    add_column :players, :confirmation_token, :string
    add_column :players, :confirmed_at, :datetime
    add_column :players, :confirmation_sent_at, :datetime
    add_column :players, :unconfirmed_email, :string

    add_index :players, :confirmation_token, unique: true
  end
end
