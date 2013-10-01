class AddToAndTitleToBookings < ActiveRecord::Migration
  def change
    add_column :bookings, :title, :string
    add_column :bookings, :to, :datetime
  end
end
