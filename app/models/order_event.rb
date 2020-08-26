class OrderEvent < ApplicationRecord
  EVENT_NAME = 'OrderEvent'
  enum event_type: { post_order: 0, put_order: 1, delete_order: 2 }

  validates :event_type, presence: true
  validates :order_status, presence: true

  def message
    {
      event_name: EVENT_NAME,
      event_type: self.event_type,
      order_id: self.order_id,
      order_status: self.order_status
    }
  end
end
