class Captain::Tools::Admin::Registry
  READ_TOOLS = [
    Captain::Tools::Admin::GetAccountSettingsService,
    Captain::Tools::Admin::ListLabelsService,
    Captain::Tools::Admin::ListCannedResponsesService,
    Captain::Tools::Admin::ListMacrosService,
    Captain::Tools::Admin::GetMacroService,
    Captain::Tools::Admin::ListInboxesService,
    Captain::Tools::Admin::GetInboxService,
    Captain::Tools::Admin::ListAutomationRulesService,
    Captain::Tools::Admin::GetAutomationRuleService
  ].freeze

  WRITE_TOOLS = [
    Captain::Tools::Admin::UpdateAccountSettingsService,
    Captain::Tools::Admin::CreateLabelService,
    Captain::Tools::Admin::UpdateLabelService,
    Captain::Tools::Admin::DeleteLabelService,
    Captain::Tools::Admin::CreateCannedResponseService,
    Captain::Tools::Admin::UpdateCannedResponseService,
    Captain::Tools::Admin::DeleteCannedResponseService,
    Captain::Tools::Admin::UpdateInboxSettingsService,
    Captain::Tools::Admin::UpdateInboxWorkingHoursService,
    Captain::Tools::Admin::CreateInboxService,
    Captain::Tools::Admin::DeleteInboxService,
    Captain::Tools::Admin::CreateAutomationRuleService,
    Captain::Tools::Admin::UpdateAutomationRuleService,
    Captain::Tools::Admin::DeleteAutomationRuleService,
    Captain::Tools::Admin::CreateMacroService,
    Captain::Tools::Admin::UpdateMacroService,
    Captain::Tools::Admin::DeleteMacroService
  ].freeze

  def self.build(assistant, user:, copilot_thread: nil)
    (READ_TOOLS + WRITE_TOOLS).map do |tool_class|
      tool_class.new(assistant, user: user, copilot_thread: copilot_thread)
    end.select(&:active?)
  end
end
