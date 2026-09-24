class Api::V1::Accounts::Captain::ToolsManifestsController < Api::V1::Accounts::BaseController
  INSTALL_ERRORS = [
    Captain::ToolsManifest::GithubSource::SourceError,
    Captain::ToolsManifest::Validator::InvalidManifestError,
    Captain::ToolsManifest::InstallService::InstallError,
    Captain::CustomTool::LimitExceededError
  ].freeze

  before_action :ensure_custom_tools_enabled
  before_action -> { check_authorization(Captain::CustomTool) }
  before_action :set_assistant

  rescue_from(*INSTALL_ERRORS) do |error|
    Rails.logger.info("[Captain::ToolsManifest] #{error.class}: #{error.message}")
    render json: { error: I18n.t('captain.tools_manifest.invalid_configuration') }, status: :unprocessable_content
  end

  def preview
    @github_source = Captain::ToolsManifest::GithubSource.new(params[:source])
    @revision = @github_source.latest_revision
    @manifest = Captain::ToolsManifest::Validator.new(@github_source.manifest(@revision)).perform
    @installed_revision = @assistant.custom_tools.from_github(@github_source.repository, @github_source.path).first&.source_metadata&.dig('revision')
  end

  def install
    @custom_tools = Captain::ToolsManifest::InstallService.new(
      assistant: @assistant,
      source: params[:source],
      revision: params[:revision],
      configuration: params.fetch(:configuration, {}).permit(inputs: {}, secrets: {}).to_h
    ).perform
  end

  private

  def ensure_custom_tools_enabled
    return if Current.account.feature_enabled?('custom_tools') || Current.account.feature_enabled?('captain_integration_v2')

    render json: { error: 'Custom tools are not enabled for this account' }, status: :forbidden
  end

  def set_assistant
    @assistant = Current.account.captain_assistants.find(params[:assistant_id])
  end
end
