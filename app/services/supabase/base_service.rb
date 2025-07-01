class Supabase::BaseService
  include HTTParty
  attr_reader :options

  def initialize(**options)
    @options = options
  end
end
