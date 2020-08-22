class CreateOrderSaga < ApplicationRecord
  enum status: {
    initialized: 0, verifing_consumer: 1, creatting_ticket: 2, authorizing_card: 3, approving_ticket: 4, approving_order: 5, order_approved: 6,
    rejecting_ticket: 7, rejecting_order: 8, order_reject: 9
  }
end
