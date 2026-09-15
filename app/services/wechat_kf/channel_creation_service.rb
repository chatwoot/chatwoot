class WechatKf::ChannelCreationService
  def initialize(account:, attributes:)
    @account = account
    @attributes = attributes
  end

  def perform
    corp_id = @attributes.require(:corp_id)
    open_kfid = @attributes.require(:open_kfid)
    integration = integration_for(corp_id)
    @account.wechat_kf_channels.create!(wechat_kf_integration: integration, open_kfid: open_kfid)
  end

  private

  def integration_for(corp_id)
    integration = WechatKfIntegration.find_by(corp_id: corp_id)
    if integration
      raise ActionController::ParameterMissing, :corp_id unless integration.account_id == @account.id

      credentials = @attributes.slice(:corp_secret, :callback_token, :encoding_aes_key)
      if credentials.present?
        @attributes.require(:corp_secret)
        @attributes.require(:callback_token)
        @attributes.require(:encoding_aes_key)
        expected = { corp_secret: integration.corp_secret, callback_token: integration.callback_token,
                     encoding_aes_key: integration.encoding_aes_key }
        raise ActionController::ParameterMissing, :existing_integration_credentials unless credentials.to_h.symbolize_keys == expected
      end
      integration
    else
      @attributes.require(:corp_secret)
      @attributes.require(:callback_token)
      @attributes.require(:encoding_aes_key)
      @account.wechat_kf_integrations.create!(@attributes.slice(:corp_id, :corp_secret, :callback_token, :encoding_aes_key))
    end
  end
end
