class CreateApiClients < ActiveRecord::Migration
  def change
    create_table :api_clients do |t|
      t.string :url
      t.string :method

      t.timestamps
    end
  end
end
