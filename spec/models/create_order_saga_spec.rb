require 'rails_helper'

RSpec.describe CreateOrderSaga, type: :model do
  let(:order) { Order.create }
  let(:saga) { CreateOrderSaga.create(order: order, status: status) }

  describe '#verify_consumer' do
    subject { saga.verify_consumer }

    let(:status) { 'initialized' }

    specify do
      subject

      expect(saga.status).to eq 'consumer_verifing'
    end
  end

  describe '#create_ticket' do
    subject { saga.create_ticket }

    let(:status) { 'consumer_verifing' }

    specify do
      subject

      expect(saga.status).to eq 'ticket_creating'
    end
  end

  describe '#authorize_card' do
    subject { saga.authorize_card }

    let(:status) { 'ticket_creating' }

    specify do
      subject

      expect(saga.status).to eq 'card_authorizing'
    end
  end

  describe '#approve_ticket' do
    subject { saga.approve_ticket }

    let(:status) { 'card_authorizing' }

    specify do
      subject

      expect(saga.status).to eq 'order_approved'
      expect(order.status).to eq 'approved'
    end
  end

  describe '#consumer_verifing_failed' do
    subject { saga.consumer_verifing_failed }

    let(:status) { 'consumer_verifing' }

    specify do
      subject

      expect(saga.status).to eq 'order_rejected'
      expect(order.status).to eq 'rejected'
    end
  end

  describe '#ticket_creating_failed' do
    subject { saga.ticket_creating_failed }

    let(:status) { 'ticket_creating' }

    specify do
      subject

      expect(saga.status).to eq 'order_rejected'
      expect(order.status).to eq 'rejected'
    end
  end

  describe '#card_authorizing_failed' do
    subject { saga.card_authorizing_failed }

    let(:status) { 'card_authorizing' }

    specify do
      subject

      expect(saga.status).to eq 'order_rejected'
      expect(order.status).to eq 'rejected'
    end
  end
end
