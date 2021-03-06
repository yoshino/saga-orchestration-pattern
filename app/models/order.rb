class Order < ApplicationRecord
  enum status: { ready: 0, approved: 1, rejected: 2 }

  has_one :create_order_saga
  has_many :order_events

  validates :status, presence: true
end
