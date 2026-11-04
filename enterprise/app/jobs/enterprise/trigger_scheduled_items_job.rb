module Enterprise::TriggerScheduledItemsJob
  def perform
    super

    ## Triggers Enterprise specific jobs
    ####################################

    Campaigns::RecoverWhatsappCampaignsJob.perform_later

    # Triggers Account Sla jobs
    Sla::TriggerSlasForAccountsJob.perform_later

    # Continues Copilot runs whose next job was lost
    Captain::Copilot::RecoverRunsJob.perform_later
  end
end
