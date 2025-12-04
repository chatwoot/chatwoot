# frozen_string_literal: true

class Llm::BaseService
  attr_reader :provider

  def initialize
    @provider = Captain::Providers::Factory.create
  end
end
