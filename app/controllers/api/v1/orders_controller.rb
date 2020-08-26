module Api
  module V1
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

      private

      def order_params
        params.require(:order).permit(:status)
      end

      def create_order_saga_params
        params.require(:create_order_saga).permit(
          :constomer_name,
          :food_name,
          :credit_card_number
        )
      end
    end
  end
end
