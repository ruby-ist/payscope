class CreateExchangeRates < ActiveRecord::Migration[8.1]
  def change
    create_table :exchange_rates do |t|
      t.string :currency, limit: 3, null: false
      t.decimal :rate, precision: 12, scale: 6, null: false

      t.timestamps
    end

    add_index :exchange_rates, :currency, unique: true
  end
end
