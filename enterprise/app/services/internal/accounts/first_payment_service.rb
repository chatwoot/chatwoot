# frozen_string_literal: true

# Records the account's first successful non-zero Stripe payment, once. Trials and other
# $0 invoices, failed attempts and plan changes never reach here, and a later paid invoice
# never replaces the first one. event_id stays the same across webhook retries.
class Internal::Accounts::FirstPaymentService
  pattr_initialize [:account!, :invoice!]

  def perform
    return unless ChatwootApp.chatwoot_cloud?
    return unless invoice['status'] == 'paid' && invoice['amount_paid'].to_i.positive?

    recorded = account.with_lock do
      next false if internal_attributes_service.get('first_payment').present?

      internal_attributes_service.set('first_payment', first_payment)
    end
    Internal::Accounts::XConversionTrackingJob.perform_later(account.id, 'cloud_first_payment') if recorded
  end

  private

  def first_payment
    {
      'event_id' => "cloud_first_payment-account-#{account.id}",
      'invoice_id' => invoice['id'],
      'paid_at' => Time.zone.at(invoice['status_transitions']['paid_at']).iso8601,
      'amount_paid' => invoice['amount_paid'],
      'currency' => invoice['currency']
    }
  end

  def internal_attributes_service
    @internal_attributes_service ||= Internal::Accounts::InternalAttributesService.new(account)
  end
end
