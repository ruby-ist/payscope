class AddLastSyncedAtToExchangeRates < ActiveRecord::Migration[8.1]
  def change
    add_column :exchange_rates, :last_synced_at, :datetime
  end
end
