class CreateBookings < ActiveRecord::Migration
  def change
    create_table :bookings do |t|
      t.belongs_to :synchronization
      t.string :cobot_id, :uid
      t.datetime :from
      t.timestamps
    end
  end
end
