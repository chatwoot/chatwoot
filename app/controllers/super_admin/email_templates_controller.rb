class SuperAdmin::EmailTemplatesController < SuperAdmin::ApplicationController
  def index
    @global_templates = GlobalEmailTemplate.all
    @account_templates = AccountEmailTemplate.all
    @advanced_templates = AdvancedEmailTemplate.all
  end
end
