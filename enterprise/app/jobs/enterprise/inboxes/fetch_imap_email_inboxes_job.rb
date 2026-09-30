module Enterprise::Inboxes::FetchImapEmailInboxesJob
  private

  def cloud_account_can_fetch_emails?(account)
    return super unless account.billing_provider == 'shopify'

    account.feature_enabled?('inbound_emails')
  end
end
