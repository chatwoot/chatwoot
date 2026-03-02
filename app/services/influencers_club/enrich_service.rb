class InfluencersClub::EnrichService
  def initialize(client: InfluencersClub::Client.new)
    @client = client
  end

  # Returns full profile + audience data. Costs 1 credit.
  def perform(username:, platform: 'instagram')
    @client.post('/public/v1/creators/enrich/handle/full/', {
                   platform: platform,
                   handle: username
                 })
  end
end
