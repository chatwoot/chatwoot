class Api::V1::Accounts::Integrations::Moengage::TemplateMappingsController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization?
  before_action :fetch_hook
  before_action :fetch_mapping, only: %i[update destroy]

  def index
    mappings = @hook.moengage_template_mappings.includes(:inbox)
    render json: { payload: mappings.map { |m| mapping_response(m) } }
  end

  def create
    mapping = @hook.moengage_template_mappings.create!(mapping_params.merge(account: Current.account))
    render json: mapping_response(mapping), status: :created
  end

  def update
    @mapping.update!(mapping_params)
    render json: mapping_response(@mapping)
  end

  def destroy
    @mapping.destroy!
    head :ok
  end

  def available_templates
    inbox = Current.account.inboxes.find(params[:inbox_id])
    return render json: { error: 'Not a WhatsApp inbox' }, status: :unprocessable_entity unless inbox.channel_type == 'Channel::Whatsapp'

    templates = inbox.channel.message_templates&.select { |t| t['status']&.downcase == 'approved' } || []

    render json: {
      payload: templates.map do |t|
        {
          name: t['name'],
          language: t['language'],
          namespace: t['namespace'],
          components: t['components'],
          parameter_format: t['parameter_format']
        }
      end
    }
  end

  private

  def fetch_hook
    @hook = Current.account.hooks.find_by!(app_id: 'moengage')
  end

  def fetch_mapping
    @mapping = @hook.moengage_template_mappings.find(params[:id])
  end

  def mapping_params
    permitted = params.require(:template_mapping).permit(
      :event_name, :inbox_id, :template_name, :template_language, :enabled
    )
    permitted[:parameter_map] = params[:template_mapping][:parameter_map].permit!.to_h if params.dig(:template_mapping, :parameter_map).present?
    permitted
  end

  def mapping_response(mapping)
    {
      id: mapping.id,
      event_name: mapping.event_name,
      inbox_id: mapping.inbox_id,
      inbox_name: mapping.inbox.name,
      template_name: mapping.template_name,
      template_language: mapping.template_language,
      parameter_map: mapping.parameter_map,
      enabled: mapping.enabled,
      created_at: mapping.created_at,
      updated_at: mapping.updated_at
    }
  end
end
