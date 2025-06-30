class Integrations::Zalo::OfficialAccount < Integrations::Zalo::Authenticated
  def detail
    client.get('v2.0/oa/getoa')
  end
end
