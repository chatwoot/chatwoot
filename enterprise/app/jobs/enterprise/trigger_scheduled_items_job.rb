module Enterprise::TriggerScheduledItemsJob
  def perform
    super

    ## Triggers Enterprise specific jobs
    ####################################

    Campaigns::RecoverWhatsappCampaignsJob.perform_later

    # Triggers Account Sla jobs
    Sla::TriggerSlasForAccountsJob.perform_later
  end
end
