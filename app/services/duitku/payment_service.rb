class Duitku::PaymentService
    include HTTParty
    
    def initialize
      @base_url = ENV['DUITKU_BASE_URL'] || 'https://sandbox.duitku.com'
      @merchant_code = ENV['DUITKU_MERCHANT_CODE']
      @api_key = ENV['DUITKU_API_KEY']
    end
    
    def create_payment(params)
      Rails.logger.info "PARAMS: #{params}"
      # Rails.logger.info "SIGNATURE STRING: #{@merchant_code}#{order_id}#{amount}#{@api_key}"
      # Rails.logger.info "FINAL SIGNATURE: #{generate_signature(amount, order_id)}"

      payload = {
        merchantCode: @merchant_code,
        paymentAmount: params[:amount],
        paymentMethod: params[:payment_method],
        merchantOrderId: params[:order_id],
        productDetails: params[:product_details],
        customerVaName: params[:customer_name],
        customerEmail: params[:customer_email],
        customerPhoneNumber: params[:customer_phone],
        callbackUrl: "#{ENV['DUITKU_CALLBACK_URL']}/api/v1/duitku/webhook",
        returnUrl: "#{params[:return_url]}",
        signature: generate_signature(params[:amount], params[:order_id]),
        expiryPeriod: 60 # dalam menit
      }
      
      response = HTTParty.post(
        "#{@base_url}/webapi/api/merchant/v2/inquiry",
        body: payload.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
      
      if response.success?
        parsed_response = JSON.parse(response.body)
        
        # Simpan informasi pembayaran ke conversation
        if params[:conversation_id].present?
          conversation = Conversation.find_by(id: params[:conversation_id])
          if conversation
            custom_attributes = conversation.custom_attributes || {}
            custom_attributes['duitku_order_id'] = params[:order_id]
            custom_attributes['duitku_payment_url'] = parsed_response['paymentUrl']
            conversation.update(custom_attributes: custom_attributes)
          end
        end
        
        parsed_response.merge(payload)
      else
        { error: response.body, status: response.code }
      end
    end
    
    private
    
    # def generate_signature(amount, order_id)
    #   timestamp = Time.now.strftime('%Y%m%d%H%M%S')
    #   md5_hash = Digest::MD5.hexdigest("#{@merchant_code}#{timestamp}#{@api_key}")
    #   signature_components = "#{@merchant_code}#{amount}#{order_id}#{timestamp}#{md5_hash}"
    #   Digest::SHA256.hexdigest(signature_components)
    # end
    
    def generate_signature(amount, order_id)
      timestamp = Time.now.strftime('%Y%m%d%H%M%S')
      Digest::MD5.hexdigest("#{@merchant_code}#{order_id}#{amount}#{@api_key}")
    end
  end