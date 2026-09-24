class Api::V1::Accounts::Captain::ToolsManifestsController < Api::V1::Accounts::BaseController
  InstallError = Captain::ToolsManifest::InstallService::InstallError

  before_action :ensure_custom_tools_enabled
  before_action -> { check_authorization(Captain::CustomTool) }
  before_action :set_assistant

  rescue_from(Captain::ToolsManifest::GithubSource::SourceError) { |error| render_install_error(error, 'invalid_source') }
  rescue_from(Captain::ToolsManifest::Validator::InvalidManifestError) { |error| render_install_error(error, 'invalid_manifest') }
  rescue_from(InstallError) { |error| render_install_error(error, 'invalid_configuration') }
  rescue_from(Captain::CustomTool::LimitExceededError) { |error| render json: { error: error.message }, status: :unprocessable_content }

  def preview
    @github_source = Captain::ToolsManifest::GithubSource.new(params[:source])
    @revision = @github_source.latest_revision
    @manifest = Captain::ToolsManifest::Validator.new(@github_source.manifest(@revision)).perform
    @installed_revision = @assistant.custom_tools.from_github(@github_source.repository, @github_source.path).first&.source_metadata&.dig('revision')
  end

  def install
    @custom_tools = Captain::ToolsManifest::InstallService.new(
      assistant: @assistant, source: params[:source], revision: revision_param, configuration: configuration_param
    ).perform
  end

  private

  # permit would raise on a string or array, so reject anything that isn't an object first
  def configuration_param
    configuration = params.fetch(:configuration, {})
    raise InstallError, 'Configuration must be an object' unless configuration.is_a?(ActionController::Parameters)

    configuration.permit(inputs: {}, secrets: {}).to_h
  end

  def revision_param
    revision = params[:revision]
    raise InstallError, 'Revision must be a string' unless revision.nil? || revision.is_a?(String)

    revision
  end

  def ensure_custom_tools_enabled
    return if Current.account.feature_enabled?('custom_tools') || Current.account.feature_enabled?('captain_integration_v2')

    render json: { error: 'Custom tools are not enabled for this account' }, status: :forbidden
  end

  # The detailed reason is for logs; users get a short translated message
  def render_install_error(error, message_key)
    Rails.logger.info("[Captain::ToolsManifest] #{error.class}: #{error.message}")
    render json: { error: I18n.t("captain.tools_manifest.#{message_key}") }, status: :unprocessable_content
  end

  def set_assistant
    @assistant = Current.account.captain_assistants.find(params[:assistant_id])
  end
end
