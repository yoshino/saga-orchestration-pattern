class PollingSubscriber
  SUBSCRIBED_ENDPOINT = "#{ENV['ELASTICMQ_URL']}/queue/SagaOrchestrationProject"
  MESSAGE_PARAMS = {
    max_number_of_messages: 10,
    wait_time_seconds: 20
  }

  class << self
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

        sqs_message.delete
      end
    end
  end
end
