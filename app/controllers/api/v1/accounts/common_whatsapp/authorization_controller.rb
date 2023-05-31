class Api::V1::Accounts::CommonWhatsapp::AuthorizationController < Api::V1::Accounts::BaseController
    require 'json'

    @secret_key

    def get_qr_code
        @secret_key = ENV.fetch('WPP_CONNECT_SECRET_KEY', "")
        phone_number = params[:channel][:phone_number]
        # First generate token
        token = generate_token(phone_number)
        if token.empty?
            render json: { success: false, message: "Falha na obtenção do token" }
        else
            token = token['token']
            Rails.logger.info('TOKEN')
            Rails.logger.info(token)

            # Then start-session (generate-qr-code)
            qrcode = generate_qr_code(phone_number, token)
            Rails.logger.info('QrCode')
            Rails.logger.info(qrcode)

            if qrcode.empty?
                render json: { success: false, message: "Falha na obtenção do QrCode" }
            else
                qrcode = qrcode['qrcode']
                render json: { success: true, qrcode: qrcode }
            end
        end
    end

    def check_conn_status
        @secret_key = ENV.fetch('WPP_CONNECT_SECRET_KEY', "")
        phone_number = params[:channel][:phone_number]
        # First generate token
        token = generate_token(phone_number)
        if token.empty?
            render json: { success: false, message: "Falha na obtenção do token" }
        else
            token = token['token']

            # Then check status-session
            status = status_session(phone_number, token)
            Rails.logger.info('Status')
            Rails.logger.info(status)

            if status.empty?
                render json: { success: false, message: "Falha na obtenção do Status" }
            else
                status = status['status']
                render json: { success: true, status: status }
            end
        end
    end

    private

    def generate_token(phone_number)
        response = HTTParty.post(
            "#{api_base_path(phone_number)}/#{@secret_key.to_s}/generate-token"
        )

        process_response(response)
    end

    def generate_qr_code(phone_number, token)
        response = HTTParty.post(
            "#{api_base_path(phone_number)}/start-session",
            headers: { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' },
            body: {
                webhook: nil,
                waitQrCode: true
            }.to_json
        )

        process_response(response)
    end

    def status_session(phone_number, token)
        response = HTTParty.get(
            "#{api_base_path(phone_number)}/status-session",
            headers: { 'Authorization' => "Bearer #{token}", 'Content-Type' => 'application/json' }
        )

        process_response(response)
    end
    
    def api_base_path(session)
        "http://localhost:21465/api/#{session}"
    end

    def process_response(response)
        if response.success?
            Rails.logger.info("REQUEST")
            Rails.logger.info(response)
            response.parsed_response
        else
            Rails.logger.error response.body
            nil
        end
    end
end
