class Integrations::Zalo::User < Integrations::Zalo::Authenticated
  def detail(user_id)
    request_data = { user_id: user_id }
    client
      .query(data: request_data.to_json)
      .get('v3.0/oa/user/detail')
  end
end
