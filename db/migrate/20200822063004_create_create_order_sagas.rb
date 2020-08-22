class CreateCreateOrderSagas < ActiveRecord::Migration[6.0]
  def change
    create_table :create_order_sagas do |t|
      t.integer :status, null: false, default: 0
      t.references :order, foreign_key: true

      t.timestamps
    end
  end
end
