require 'rails_helper'

RSpec.describe "Api::V1::Orders", type: :request do
  describe 'Post /orders' do
    subject { post '/api/v1/orders', params: { order: { status: status }} }

    context 'success' do
      let(:status) { 'ready' }

      it do
        expect { subject }.to change { Order.count }.by(1)
                          .and change { OrderEvent.count }.by(1)
        expect(OrderEvent.where(order_id: JSON.parse(response.body)['data']['id'], event_type: 'create_order').exists?).to be_truthy
      end
    end

    context 'error' do
      let(:status) { nil }

      it do
        expect { subject }.to change { Order.count }.by 0
        expect(JSON.parse(response.body)['data']).to eq({ 'status' => ["can't be blank"] })
      end
    end
  end
end
