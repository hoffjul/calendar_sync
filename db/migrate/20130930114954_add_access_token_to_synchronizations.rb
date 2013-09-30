class AddAccessTokenToSynchronizations < ActiveRecord::Migration
  def change
    add_column :synchronizations, :access_token, :string
  end
end
