module DouyinHelper
  # @access_token_response
  def post_douyin_access_token(account_douyin_hook)
    HTTParty.post(
      'https://open.douyin.com/oauth/access_token/',
      headers: { 'Content-Type' => 'application/json' },
      body: {
        grant_type: 'authorization_code',
        client_key: account_douyin_hook['settings']['client_key'],
        client_secret: account_douyin_hook['settings']['client_secret'],
        code: params[:code]
      }.to_json
    )
  end

  # @userinfo_response
  # @douyin_nickname = @userinfo_response['data']['nickname']
  # @douyin_avatar = @userinfo_response['data']['avatar']
  def post_douyin_user_info(account_douyin_hook)
    HTTParty.post(
      'https://open.douyin.com/oauth/userinfo/',
      headers: { 'Content-Type' => 'application/x-www-form-urlencoded' },
      body: "open_id=#{account_douyin_hook.reference_id}&access_token=#{account_douyin_hook.access_token}"
    )
  end

  def e_account_role(str)
    roles = {
      'EAccountM' => '普通企业号',
      'EAccountS' => '认证企业号',
      'EAccountK' => '品牌企业号'
    }
    roles[str]
  end
end
