class HandleStripeEvent
  def call(event:)
    case event["type"]
    when 'checkout.session.completed'
      session = event.data.object
    when 'customer.subscription.created'
      subscription = event.data.object
    when 'customer.subscription.deleted'
      subscription = event.data.object
    when 'customer.subscription.updated'
      subscription = event.data.object
    else
        puts "Unhandled event type: #{event.type}"
    end

    byebug
  end
end