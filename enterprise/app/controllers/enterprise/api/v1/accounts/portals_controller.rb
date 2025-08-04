module Enterprise::Api::V1::Accounts::PortalsController
  def ssl_status
    return render_could_not_create_error(I18n.t('portals.ssl_status.custom_domain_not_configured')) if @portal.custom_domain.blank?

    result = Cloudflare::CheckCustomHostnameService.new(portal: @portal).perform

    return render_could_not_create_error(result[:errors]) if result[:errors].present?

    ssl_settings = @portal.ssl_settings || {}
    render json: {
      status: ssl_settings['cf_status'],
      verification_errors: ssl_settings['cf_verification_errors']
    }
  end

  def upload_content
    pdf_file = params[:pdf_file]
    additional_context = params[:additional_context]

    return render_error('PDF file is required', :bad_request) if pdf_file.blank?
    return render_error('Invalid file type', :bad_request) unless pdf_file.content_type == 'application/pdf'
    return render_error('File too large (max 512MB)', :bad_request) if pdf_file.size > 512.megabytes

    # Find or create a Captain assistant for this portal
    assistant = find_or_create_portal_assistant

    # Create a document record with the PDF
    document = assistant.documents.create!(
      name: pdf_file.original_filename,
      external_link: pdf_file.original_filename, # Use filename as external_link for uniqueness
      account: Current.account
    )

    # Attach the PDF file
    document.pdf_file.attach(pdf_file)

    render json: {
      success: true,
      document: document.as_json(only: [:id, :name, :status, :created_at])
    }, status: :created
  rescue StandardError => e
    Rails.logger.error "PDF upload error: #{e.message}"
    render_error('Failed to upload PDF', :internal_server_error)
  end

  def generated_content
    assistant = find_portal_assistant
    return render_error('No assistant found for this portal', :not_found) unless assistant

    responses = Captain::AssistantResponse.where(assistant: assistant)
                                          .includes(:documentable)
                                          .order(created_at: :desc)

    render json: {
      responses: responses.as_json(
        include: {
          documentable: { only: [:id, :name, :status], methods: [:pdf_document?] }
        }
      )
    }
  end

  def publish_content
    response_ids = params[:response_ids] || []
    category_id = params[:category_id]

    return render_error('No responses selected', :bad_request) if response_ids.empty?

    assistant = find_portal_assistant
    return render_error('No assistant found for this portal', :not_found) unless assistant

    responses = assistant.responses.where(id: response_ids)
    created_articles = []

    responses.each do |response|
      article = @portal.articles.create!(
        title: response.question.truncate(255),
        content: response.answer,
        author: Current.user,
        status: :draft,
        category_id: category_id,
        meta: {
          source: 'pdf_generation',
          assistant_response_id: response.id,
          document_name: response.documentable&.name
        }
      )
      created_articles << article
    end

    render json: {
      success: true,
      articles: created_articles.as_json(only: [:id, :title, :status, :created_at])
    }, status: :created
  rescue StandardError => e
    Rails.logger.error "Content publishing error: #{e.message}"
    render_error('Failed to publish content', :internal_server_error)
  end

  private

  def find_or_create_portal_assistant
    assistant_name = "Portal Assistant - #{@portal.name}"
    Current.account.captain_assistants.find_or_create_by(name: assistant_name) do |assistant|
      assistant.description = "AI assistant for generating content for the #{@portal.name} portal"
    end
  end

  def find_portal_assistant
    assistant_name = "Portal Assistant - #{@portal.name}"
    Current.account.captain_assistants.find_by(name: assistant_name)
  end

  def render_error(message, status)
    render json: { error: message }, status: status
  end
end
