class CreateOrderEvents < ActiveRecord::Migration[6.0]
  def change
    create_table :order_events do |t|
      t.integer :event_type, null: false

      # order's data
      t.references :order
      t.integer :order_status, null: false

      t.timestamps
    end
  end
end
