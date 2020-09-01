require 'rails_helper'

RSpec.describe PollingSubscriber, type: :model do
  describe '.fetch_messages' do
    subject { described_class.fetch_messages }

    let(:order) { Order.create }
    let!(:saga) { CreateOrderSaga.create(order: order) }

    # elasticmqを用いた擬似SQSを用いてテストする
    let(:sqs_endpoint) { ENV['ELASTICMQ_URL'] }
    let(:event) { event }
    let(:sqs_client) {
      Aws::SQS::Client.new(
        endpoint: sqs_endpoint,
        region: 'ap-northeast-1',
      )
    }

    let(:event) {
      {
        event_name: event_name,
        status: event_status,
        order_id: order.id
      }
    }

    before do
      allow(Aws::SQS::Client).to receive(:new).and_return(sqs_client)
      sqs_client.create_queue(queue_name: 'SagaOrchestrationProject')

      sqs_client.send_message(
        queue_url: "#{sqs_endpoint}/queue/SagaOrchestrationProject",
        message_body: event.to_json
      )
    end

    after do
      sqs_client.delete_queue(queue_url: "#{sqs_endpoint}/queue/SagaOrchestrationProject")
    end

    context 'event_name: ConsumerServiceConsumerVerified' do
      let(:event_name) { 'ConsumerServiceConsumerVerified' }

      before do
        saga.verify_consumer
      end

      context 'success' do
        let(:event_status) { 200 }

        specify do
          subject

          expect(saga.reload.status).to eq 'ticket_creating'
        end
      end

      context 'failed' do
        let(:event_status) { 404 }

        specify do
          subject

          expect(saga.reload.status).to eq 'order_rejected'
          expect(order.reload.status).to eq 'rejected'
        end
      end
    end

    context 'event_name: KitchenServiceTicketCreated' do
      let(:event_name) { 'KitchenServiceTicketCreated' }

      before do
        saga.verify_consumer
        saga.create_ticket
      end

      context 'success' do
        let(:event_status) { 200 }

        specify do
          subject

          expect(saga.reload.status).to eq 'card_authorizing'
        end
      end

      context 'failed' do
        let(:event_status) { 404 }

        specify do
          subject

          expect(saga.reload.status).to eq 'order_rejected'
          expect(order.reload.status).to eq 'rejected'
        end
      end
    end

    context 'event_name: AccountingServiceCardAuthorized' do
      let(:event_name) { 'AccountingServiceCardAuthorized' }

      before do
        saga.verify_consumer
        saga.create_ticket
        saga.authorize_card
      end

      context 'success' do
        let(:event_status) { 200 }

        specify do
          subject

          expect(saga.reload.status).to eq 'order_approved'
        end
      end

      context 'failed' do
        let(:event_status) { 404 }

        specify do
          subject

          expect(saga.reload.status).to eq 'order_rejected'
          expect(order.reload.status).to eq 'rejected'
        end
      end
    end
  end
end
