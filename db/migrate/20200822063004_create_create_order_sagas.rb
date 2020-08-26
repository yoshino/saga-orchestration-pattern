class CreateCreateOrderSagas < ActiveRecord::Migration[6.0]
  def change
    create_table :create_order_sagas do |t|
      t.integer :status, null: false, default: 0
      t.references :order, foreign_key: true

      t.string :consumer_name # for ConsumerService
      t.string :food_name # for KitchenService
      t.string :credit_card_number # for AccountingService

      t.timestamps
    end
  end
end
