# Saga Orchestration Patten

## What is saga orchestration pattern?
ref: https://microservices.io/patterns/data/saga.html

### Context
You have applied the Database per Service pattern. Each service has its own database. Some business transactions, however, span multiple service so you need a mechanism to implement transactions that span services. For example, let’s imagine that you are building an e-commerce store where customers have a credit limit. The application must ensure that a new order will not exceed the customer’s credit limit. Since Orders and Customers are in different databases owned by different services the application cannot simply use a local ACID transaction.

### Problem
How to implement transactions that span services?

### Forces
2PC is not an option

### Solution
Implement each business transaction that spans multiple services is a saga. A saga is a sequence of local transactions. Each local transaction updates the database and publishes a message or event to trigger the next local transaction in the saga. If a local transaction fails because it violates a business rule then the saga executes a series of compensating transactions that undo the changes that were made by the preceding local transactions.


## Example by Ruby on Rails
### 1: Create order and create_order_saga
If you need to publish event, you should use [Pattern: transactional outbox + polling-publisher](https://github.com/yoshino/transactional-outbox_polling-publisher-pattern).


```rb
    class OrdersController < ApplicationController
      def create
        order = Order.new(order_params)

        if order.valid?
          ActiveRecord::Base.transaction do
            order.save
            order.create_create_order_saga(create_order_saga_params)
            order.order_events.create(event_type: 'post_order', order_status: order.status)
          end

          order.create_order_saga.verify_consumer

          render json: { data: order }
        else
          render json: { data: order.errors }
        end
      end
```

create_order_saga chnages the status and hits ConsumerService API (you can do the same thing through a event).

```rb
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
```

### 2: create_order_saga gives directions accorfing to the event and the status
PollingWorker fetches events and identify the saga by the event's parameter, ordre_id.

```rb
    def polling
      while true do
        fetch_messages
      end
    end

    def fetch_messages
      messages = Aws::SQS::Queue.new(SUBSCRIBED_ENDPOINT).receive_messages(MESSAGE_PARAMS)

      messages.each do |sqs_message|
        event = JSON.parse(sqs_message.body)
        saga = Order.find(event['order_id']).create_order_saga

        case event['event_name']
        when 'ConsumerServiceConsumerVerified'
          if event['status'] == 200
            saga.create_ticket
          else
            saga.consumer_verifing_failed
          end
        when 'KitchenServiceTicketCreated'
          if event['status'] == 200
            saga.authorize_card
          else
            saga.ticket_creating_failed
          end
        when 'AccountingServiceCardAuthorized'
          if event['status'] == 200
            saga.approve_ticket
          else
            saga.card_authorizing_failed
          end
        end
```
