module Enterprise::TriggerScheduledItemsJob
  def perform
    super

    ## Triggers Enterprise specific jobs
    ####################################

    # Triggers Account Sla jobs
    Sla::TriggerSlasForAccountsJob.perform_later
  end
end
