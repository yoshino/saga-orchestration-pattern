class CreateOrderSaga < ApplicationRecord
  class ConsumerProxyServiceError < StandardError; end

  belongs_to :order

  enum status: { initialized: 0, consumer_verifing: 1, ticket_creating: 2, card_authorizing: 3, ticket_approving: 4,
                 order_approving: 5, order_approved: 6, ticket_rejecting: 7, order_rejecting: 8, order_rejected: 9 } do

    event :verify_consumer do
      before do
        Services::ConsumerService.verify_consumer(order_id, consumer_name)
      end

      transition :initialized => :consumer_verifing
    end

    # the polling worker fetch the event from the endpoint of que of ConsumerServiceVerifiedEvent.
    # if success, :consummer_verifing => :ticket_creating
    # else :consummer_verifing => :order_rejecting
    event :create_ticket do
      before do
        Services::KitchenService.create_ticket(order_id, food_name)
      end

      transition :consumer_verifing => :ticket_creating
    end

    # When the polling worker fetch the event from the endpoint of que of KitchenServiceTicketCreatedEvent.
    # if success, :ticket_creating => :card_authorizing
    # else :ticket_creating => :order_rejecting
    event :authorize_card do
      before do
        Services::AccountingService.authorize_card(order_id, credit_card_number)
      end

      transition :ticket_creating => :card_authorizing
    end

    # When the polling worker fetch the event from the endpoint of que of AccountingServiceCardAuthorizedEvent.
    # if success, :card_authorizing => ticket_approving
    # else :card_authorizing => :ticket_rejecting
    event :approve_ticket do
      before do
        Services::KitchenService.approve_ticket(order_id)
      end

      after do
        approve_order
      end

      transition :card_authorizing => :ticket_approving
    end

    event :approve_order do
      after do
        approved_order
      end

      transition :ticket_approving => :order_approving
    end

    event :approved_order do
      before do
        order.approved!
      end

      transition :order_approving => :order_approved
    end

    #-------------------------------------
    # compansation event
    #-------------------------------------
    event :consumer_verifing_failed do
      after do
        reject_order
      end

      transition :consumer_verifing => :order_rejecting
    end

    event :ticket_creating_failed do
      after do
        reject_order
      end

      transition :ticket_creating => :order_rejecting
    end

    event :card_authorizing_failed do
      after do
        reject_ticket
      end

      transition :card_authorizing  => :ticket_rejecting
    end

    event :reject_order do
      before do
        order.rejected!
      end

      transition :order_rejecting => :order_rejected
    end

    event :reject_ticket do
      before do
        Services::KitchenService.reject_ticket(order_id)
      end

      after do
        reject_order
      end

      transition :ticket_rejecting => :order_rejecting
    end
  end
end
