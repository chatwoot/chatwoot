class Facebook::PageDetailsService
  pattr_initialize [:access_token!]

  def perform
    response = Koala::Facebook::API.new(access_token).get_connections(
      'me', '', { fields: 'name,instagram_business_account' }
    )

    {
      provider_name: response['name'],
      instagram_id: response.dig('instagram_business_account', 'id')
    }
  end
end
