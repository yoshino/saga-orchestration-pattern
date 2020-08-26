class PollingPublisher
  SNS_TOPIC_ARN = Settings.order_event_publish_endpoint

  def polling
    while true do
      publish_order_event
    end
  end

  def publish_order_event
    OrderEvent.all.each do |event|
      message_id = topic.publish(message: event.message.to_json)
      event.destroy! if message_id
    end
  end

  private

  def topic
    @topic ||= begin
      sns = Aws::SNS::Resource.new(client: sns_client)
      sns.topic(SNS_TOPIC_ARN)
    end
  end

  def sns_client
    Aws::SNS::Client.new(
      access_key_id: Settings.aws.access_key_id,
      secret_access_key: Settings.aws.secret_access_key,
      region: Settings.aws.region
    )
  end
end
