class CreateSynchronizations < ActiveRecord::Migration
  def change
    create_table :synchronizations do |t|
      t.string :ics_url, :resource_id, :subdomain
    end
  end
end
