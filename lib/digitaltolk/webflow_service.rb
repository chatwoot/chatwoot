class Digitaltolk::WebflowService
  attr_accessor :params
  
  def initialize(params)
    @params = params
  end

  def perform
    puts '----------------------------------------------'
    puts "webflow_params: #{params}"
    puts '----------------------------------------------'
  end
end