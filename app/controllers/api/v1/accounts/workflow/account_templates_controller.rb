class Api::V1::Accounts::Workflow::AccountTemplatesController < Api::V1::Accounts::BaseController
  before_action :current_account
  before_action :account_template, except: [:index, :create]
  before_action :check_authorization

  def index
    @account_templates = Current.account.workflow_account_templates
  end

  def create
    ActiveRecord::Base.transaction do
      @account_template = Current.account.workflow_account_templates.create!(permitted_params)
      update_inboxes_list
    rescue StandardError => e
      Rails.logger.info e
    end
  end

  def update
    ActiveRecord::Base.transaction do
      @account_template.update!(update_params)
      update_inboxes_list
    rescue StandardError => e
      Rails.logger.info e
    end
  end

  def destroy
    @account_template.destroy
    head :ok
  end

  private

  def update_inboxes_list
    inboxes_to_be_added_ids.each { |user_id| @account_template.add_inbox(user_id) }
    inboxes_to_be_removed_ids.each { |user_id| @account_template.remove_inbox(user_id) }
  end

  def inboxes_to_be_added_ids
    params[:inbox_ids] - current_inboxes_ids
  end

  def inboxes_to_be_removed_ids
    current_inboxes_ids - params[:inbox_ids]
  end

  def current_inboxes_ids
    @current_inboxes_ids = @account_template.inboxes.pluck(:id)
  end

  def account_template
    @account_template = Current.account.workflow_account_templates.find(params[:id])
  end

  def check_authorization
    authorize(Workflow::AccountTemplate)
  end

  def update_params
    # only allow to update the config, not the template id
    permitted_params.except(:template_id)
  end

  def permitted_params
    params.require(:account_template).permit(:template_id, config: {})
  end
end
