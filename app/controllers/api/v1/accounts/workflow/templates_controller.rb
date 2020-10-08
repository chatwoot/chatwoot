class Api::V1::Accounts::Workflow::TemplatesController < Api::V1::Accounts::BaseController
  before_action :fetch_workflow_templates, only: [:index]

  def index; end

  private

  def fetch_workflow_templates
    @workflow_templates = Workflow::Template.all
  end
end
