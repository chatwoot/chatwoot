class Api::V1::DuitkuController < Api::V1::BaseController
    skip_before_action :authenticate_user!
    skip_before_action :verify_authenticity_token, only: [:webhook]
  
    def webhook
      # Memvalidasi signature dari Duitku untuk keamanan
      unless valid_signature?
        render json: { error: 'Invalid signature' }, status: :unauthorized
        return
      end
  
      # Memproses data yang diterima dari webhook Duitku
      notification = params.permit!.to_h
      payment_status = notification['status']
      merchant_order_id = notification['merchantOrderId']
      
      # Mencari conversation terkait berdasarkan referensi order
      conversation = Conversation.find_by(custom_attributes: { duitku_order_id: merchant_order_id })
      
      if conversation
        # Membuat pesan dalam conversation
        message_content = payment_status_message(notification)
        
        conversation.messages.create!(
          account_id: conversation.account_id,
          message_type: :outgoing,
          content: message_content,
          sender: conversation.assignee || conversation.account.agents.first
        )
        
        # Update status conversation jika pembayaran berhasil
        if payment_status == 'SUCCESS'
          conversation.update(status: :resolved)
        end
      end
  
      render json: { success: true }
    end
  
    private
  
    def valid_signature?
      # Implementasi validasi signature dari Duitku
      # Referensi: https://docs.duitku.com/api/id/#callback
      received_signature = request.headers['X-DUITKU-SIGNATURE']
      api_key = ENV['DUITKU_API_KEY']
      
      payload = request.raw_post
      computed_signature = Base64.strict_encode64(
        OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), api_key, payload)
      )
      
      ActiveSupport::SecurityUtils.secure_compare(received_signature, computed_signature)
    end
    
    def payment_status_message(notification)
      status = notification['status']
      amount = notification['amount']
      payment_method = notification['paymentMethod']
      
      case status
      when 'SUCCESS'
        "✅ Pembayaran sebesar Rp #{amount} melalui #{payment_method} telah berhasil."
      when 'PENDING'
        "⏳ Menunggu pembayaran sebesar Rp #{amount} melalui #{payment_method}."
      when 'CANCELED'
        "❌ Pembayaran sebesar Rp #{amount} melalui #{payment_method} telah dibatalkan."
      when 'FAILED'
        "❌ Pembayaran sebesar Rp #{amount} melalui #{payment_method} gagal."
      else
        "Status pembayaran: #{status}"
      end
    end
  end