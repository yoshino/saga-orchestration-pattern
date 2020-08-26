module Api
  module V1
    class OrdersController < ApplicationController
      def create
        order = Order.new(order_params)

        if order.valid?
          ActiveRecord::Base.transaction do
            order.save
            order.order_events.create(event_type: 'post_order', order_status: order.status)
          end

          render json: { data: order }
        else
          render json: { data: order.errors }
        end
      end

      private

      def order_params
        params.require(:order).permit(:status)
      end
    end
  end
end
