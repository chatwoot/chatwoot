class Api::V1::Accounts::TemplatesController < Api::V1::Accounts::BaseController
  # CRUD controller for managing message templates
  # Requires administrator access for create/update/delete operations

  before_action :check_admin_authorization?, except: [:index, :show, :render_template]
  before_action :fetch_template, only: [:show, :update, :destroy, :render_template]

  # GET /api/v1/accounts/:account_id/templates
  # List all templates for the account with optional filtering
  def index
    templates = Current.account.message_templates.includes(:content_blocks).order(created_at: :desc)

    # Apply filters
    templates = templates.where(category: params[:category]) if params[:category].present?

    # Filter by status - default to active templates only
    if params[:status].present?
      templates = templates.where(status: params[:status])
    else
      templates = templates.where.not(status: 'deprecated')
    end

    if params[:channel].present?
      templates = templates.where('? = ANY(supported_channels)', params[:channel])
    end

    if params[:search].present?
      search_term = "%#{params[:search]}%"
      templates = templates.where(
        'name ILIKE ? OR description ILIKE ? OR ? = ANY(tags)',
        search_term, search_term, params[:search]
      )
    end

    # Pagination
    page = params[:page]&.to_i || 1
    per_page = [params[:per_page]&.to_i || 20, 100].min

    paginated_templates = templates.offset((page - 1) * per_page).limit(per_page)

    render json: {
      templates: paginated_templates.map(&:detailed_json),
      total: templates.count,
      page: page,
      perPage: per_page
    }
  end

  # GET /api/v1/accounts/:account_id/templates/:id
  # Show a specific template with all details
  def show
    render json: @template.detailed_json(include_content_blocks: true)
  end

  # POST /api/v1/accounts/:account_id/templates
  # Create a new template
  def create
    @template = Current.account.message_templates.new(template_params)

    if @template.save
      # Create content blocks if provided
      create_content_blocks(params[:content_blocks]) if params[:content_blocks].present?

      # Create channel mappings if provided
      create_channel_mappings(params[:channel_mappings]) if params[:channel_mappings].present?

      render json: @template.detailed_json(include_content_blocks: true), status: :created
    else
      render json: { error: 'Failed to create template', errors: @template.errors.full_messages },
             status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "[Templates] Create failed: #{e.message}"
    render json: { error: 'Failed to create template', details: e.message }, status: :internal_server_error
  end

  # PUT /api/v1/accounts/:account_id/templates/:id
  # Update an existing template
  def update
    if @template.update(template_params)
      # Update content blocks if provided
      if params[:content_blocks].present?
        @template.content_blocks.destroy_all
        create_content_blocks(params[:content_blocks])
      end

      # Update channel mappings if provided
      if params[:channel_mappings].present?
        @template.channel_mappings.destroy_all
        create_channel_mappings(params[:channel_mappings])
      end

      render json: @template.detailed_json(include_content_blocks: true)
    else
      render json: { error: 'Failed to update template', errors: @template.errors.full_messages },
             status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "[Templates] Update failed: #{e.message}"
    render json: { error: 'Failed to update template', details: e.message }, status: :internal_server_error
  end

  # DELETE /api/v1/accounts/:account_id/templates/:id
  # Delete a template (soft delete by setting status to 'deprecated')
  def destroy
    if @template.update(status: 'deprecated')
      render json: { message: 'Template deprecated successfully' }
    else
      render json: { error: 'Failed to deprecate template' }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error "[Templates] Delete failed: #{e.message}"
    render json: { error: 'Failed to delete template', details: e.message }, status: :internal_server_error
  end

  # POST /api/v1/accounts/:account_id/templates/:id/render
  # Render a template with provided parameters
  def render_template
    # Normalize channel type (convert "Channel::AppleMessagesForBusiness" to "apple_messages_for_business")
    channel_type = normalize_channel_type(params[:channel_type] || params[:channelType])

    service = Templates::BotRendererService.new(
      template_id: @template.id,
      parameters: params[:parameters] || {},
      channel_type: channel_type
    )

    result = service.render_for_bot

    # Log usage
    TemplateUsageLog.create!(
      message_template_id: @template.id,
      account_id: Current.account.id,
      sender_type: 'User',
      sender_id: current_user.id,
      parameters_used: params[:parameters] || {},
      channel_type: channel_type,
      success: true
    )

    render json: result
  rescue Templates::BotRendererService::ParameterValidationError => e
    render json: { error: 'Parameter validation failed', details: e.message }, status: :bad_request
  rescue StandardError => e
    Rails.logger.error "[Templates] Render failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")

    # Log failure (note: error_message column doesn't exist in schema)
    TemplateUsageLog.create!(
      message_template_id: @template.id,
      account_id: Current.account.id,
      sender_type: 'User',
      sender_id: current_user.id,
      parameters_used: params[:parameters] || {},
      channel_type: normalize_channel_type(params[:channel_type] || params[:channelType]),
      success: false
    )

    render json: { error: 'Template rendering failed', details: e.message }, status: :internal_server_error
  end

  # POST /api/v1/accounts/:account_id/templates/from_apple_message
  # Create a template from an Apple Messages for Business message
  def from_apple_message
    service = Templates::FromAppleMessageService.new(
      Current.account,
      params[:messageType] || params[:message_type],
      params[:messageData] || params[:message_data] || {},
      {
        name: params[:templateName] || params[:template_name],
        category: params[:category],
        description: params[:description],
        tags: params[:tags] || []
      }
    )

    @template = service.call

    render json: @template.detailed_json(include_content_blocks: true), status: :created
  rescue StandardError => e
    Rails.logger.error "[Templates] from_apple_message failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    render json: { error: 'Failed to create template from Apple message', details: e.message }, status: :internal_server_error
  end

  private

  def fetch_template
    @template = Current.account.message_templates.find_by(id: params[:id])
    return if @template

    render json: { error: 'Template not found' }, status: :not_found
  end

  def normalize_channel_type(channel_type)
    return nil if channel_type.blank?

    # Remove "Channel::" prefix if present
    normalized = channel_type.to_s.gsub(/^Channel::/, '')

    # Convert from CamelCase/PascalCase to snake_case
    normalized.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
              .gsub(/([a-z\d])([A-Z])/, '\1_\2')
              .downcase
  end

  def template_params
    # Handle both camelCase (from frontend) and snake_case params
    normalized_params = params[:template].to_unsafe_h.deep_transform_keys do |key|
      key.to_s.underscore.to_sym
    end

    ActionController::Parameters.new(normalized_params).permit(
      :name,
      :category,
      :description,
      :status,
      :version,
      parameters: {},
      supported_channels: [],
      tags: [],
      use_cases: []
    )
  end

  def create_content_blocks(blocks_data)
    return unless blocks_data.is_a?(Array)

    blocks_data.each_with_index do |block_data, index|
      @template.content_blocks.create!(
        block_type: block_data[:block_type] || block_data['blockType'],
        properties: block_data[:properties] || {},
        conditions: block_data[:conditions] || {},
        order_index: block_data[:order_index] || block_data['orderIndex'] || index
      )
    end
  end

  def create_channel_mappings(mappings_data)
    return unless mappings_data.is_a?(Array)

    mappings_data.each do |mapping_data|
      @template.channel_mappings.create!(
        channel_type: mapping_data[:channel_type] || mapping_data['channelType'],
        content_type: mapping_data[:content_type] || mapping_data['contentType'],
        field_mappings: mapping_data[:field_mappings] || mapping_data['fieldMappings'] || {}
      )
    end
  end
end
