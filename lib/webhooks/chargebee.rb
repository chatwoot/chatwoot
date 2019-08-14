class Webhooks::Chargebee

  SUPPORTED_EVENTS = [:subscription_created, :subscription_trial_end_reminder,
                      :subscription_activated, :subscription_cancelled,
                      :subscription_reactivated, :subscription_deleted,
                      :subscription_renewed, :payment_source_added, :subscription_changed ]

  attr_accessor :params, :account

  def initialize(params)
    @params = params
  end

  def consume
    send(event_name) if supported_event?
  end

  private

  def event_name
    @params[:event_type]
  end

  def customer_id
    @params[:content][:customer][:id]
  end

  def trial_ends_on
    trial_end = @params[:content][:subscription][:trial_end]
    DateTime.strptime(trial_end,'%s')
  end

  def supported_event?
    SUPPORTED_EVENTS.include?(event_name.to_sym)
  end

  def subscription
    @subscriptiom ||= Subscription.find_by(stripe_customer_id: customer_id)
  end

  def subscription_created
    Raven.capture_message("subscription created for #{customer_id}")
  end

  def subscription_changed
    if subscription.expiry != trial_ends_on
      subscription.expiry = trial_ends_on
      subscription.save
      subscription.trial!
    end
  end

  def subscription_trial_end_reminder
    # Raven.capture_message("subscription trial end reminder for #{customer_id}")
  end

  def subscription_activated
    subscription.active!
    Raven.capture_message("subscription activated for #{customer_id}")
  end

  def subscription_cancelled
    # if there is a reason field in response. Then cancellation is due to payment failure
    subscription.cancelled!
    Raven.capture_message("subscription cancelled for #{customer_id}")
  end

  def subscription_reactivated
    #TODO send mail to user that account is reactivated
    subscription.active!
    Raven.capture_message("subscription reactivated for #{customer_id}")
  end

  def subscription_renewed
    #TODO Needs this to show payment history.
    Raven.capture_message("subscription renewed for #{customer_id}")
  end

  def subscription_deleted
  end

  def payment_source_added
    Raven.capture_message("payment source added for #{customer_id}")
    subscription.payment_source_added!
  end
end
