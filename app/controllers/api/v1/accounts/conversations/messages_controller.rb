class Api::V1::Accounts::Conversations::MessagesController < Api::V1::Accounts::Conversations::BaseController
  before_action :ensure_api_inbox, only: :update

  def index
    @messages = message_finder.perform
  end

  def create
    user = Current.user || @resource
    # Permit các tham số trước khi gửi đến MessageBuilder
    permitted_message_params = message_create_params
    mb = Messages::MessageBuilder.new(user, @conversation, permitted_message_params)
    @message = mb.perform
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def update
    Messages::StatusUpdateService.new(message, permitted_params[:status], permitted_params[:external_error]).perform
    @message = message
  end

  def destroy
    ActiveRecord::Base.transaction do
      message.update!(content: I18n.t('conversations.messages.deleted'), content_type: :text, content_attributes: { deleted: true })
      message.attachments.destroy_all
    end
  end

  def retry
    return if message.blank?

    service = Messages::StatusUpdateService.new(message, 'sent')
    service.perform
    message.update!(content_attributes: {})
    ::SendReplyJob.perform_later(message.id)
  rescue StandardError => e
    render_could_not_create_error(e.message)
  end

  def translate
    return head :ok if already_translated_content_available?

    translated_content = Integrations::GoogleTranslate::ProcessorService.new(
      message: message,
      target_language: permitted_params[:target_language]
    ).perform

    if translated_content.present?
      translations = {}
      translations[permitted_params[:target_language]] = translated_content
      translations = message.translations.merge!(translations) if message.translations.present?
      message.update!(translations: translations)
    end

    render json: { content: translated_content }
  end

  private

  def message
    @message ||= @conversation.messages.find(permitted_params[:id])
  end

  def message_finder
    @message_finder ||= MessageFinder.new(@conversation, params)
  end

  def permitted_params
    params.permit(:id, :target_language, :status, :external_error)
  end

  def message_create_params
    # Permit các tham số cần thiết cho việc tạo tin nhắn
    # Xử lý đặc biệt cho attachments với external_url
    permitted = params.permit(
      :content, :content_type, :private, :message_type, :cc_emails, :bcc_emails, :to_emails,
      :sender_type, :sender_id, :echo_id, :source_id, :external_created_at, :campaign_id,
      content_attributes: {},
      template_params: {}
    )

    # Xử lý riêng cho attachments
    if params[:attachments].present?
      # Ghi log thông tin chi tiết về attachments
      Rails.logger.info("Raw attachments: #{params[:attachments].inspect}")
      Rails.logger.info("Attachments class: #{params[:attachments].class}")

      # Chuyển đổi attachments thành mảng các hash đã được permit
      permitted[:attachments] = []

      # Xử lý tùy theo loại dữ liệu của params[:attachments]
      if params[:attachments].is_a?(Array)
        params[:attachments].each do |attachment|
          process_attachment(attachment, permitted[:attachments])
        end
      elsif params[:attachments].is_a?(ActionController::Parameters)
        # Nếu là một Parameters object (có thể xảy ra với JSON API)
        if params[:attachments][:_json].present?
          params[:attachments][:_json].each do |attachment|
            process_attachment(attachment, permitted[:attachments])
          end
        else
          process_attachment(params[:attachments], permitted[:attachments])
        end
      elsif params[:attachments].is_a?(String)
        # Nếu là chuỗi JSON, thử phân tích
        begin
          attachments_array = JSON.parse(params[:attachments])
          if attachments_array.is_a?(Array)
            attachments_array.each do |attachment|
              process_attachment(attachment, permitted[:attachments])
            end
          else
            process_attachment(attachments_array, permitted[:attachments])
          end
        rescue JSON::ParserError => e
          Rails.logger.error("Error parsing attachments JSON: #{e.message}")
          # Nếu không phải JSON, có thể là file đơn
          permitted[:attachments] << params[:attachments]
        end
      else
        # Trường hợp khác, giữ nguyên
        permitted[:attachments] << params[:attachments]
      end
    end

    Rails.logger.info("Permitted params: #{permitted.inspect}")
    permitted
  end

  def process_attachment(attachment, attachments_array)
    Rails.logger.info("Processing attachment: #{attachment.inspect}")

    if attachment.is_a?(ActionController::Parameters)
      if attachment[:external_url].present?
        # Cho phép external_url và file_type
        Rails.logger.info("Adding attachment with external_url: #{attachment[:external_url]}")
        attachments_array << { external_url: attachment[:external_url], file_type: attachment[:file_type] || 'image' }
      else
        # Giữ nguyên attachment nếu là file
        attachments_array << attachment.to_unsafe_h
      end
    elsif attachment.is_a?(Hash)
      if attachment['external_url'].present? || attachment[:external_url].present?
        # Xử lý cả key dạng string và symbol
        external_url = attachment['external_url'] || attachment[:external_url]
        file_type = attachment['file_type'] || attachment[:file_type] || 'image'
        Rails.logger.info("Adding attachment with external_url from hash: #{external_url}")
        attachments_array << { external_url: external_url, file_type: file_type }
      else
        # Giữ nguyên attachment nếu là file
        attachments_array << attachment
      end
    else
      # Giữ nguyên attachment nếu là file hoặc signed_id
      attachments_array << attachment
    end
  end

  def already_translated_content_available?
    message.translations.present? && message.translations[permitted_params[:target_language]].present?
  end

  # API inbox check
  def ensure_api_inbox
    # Only API inboxes can update messages
    render json: { error: 'Message status update is only allowed for API inboxes' }, status: :forbidden unless @conversation.inbox.api?
  end
end
