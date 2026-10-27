# Where Chatwoot reads a tool parameter's value instead of asking the model.
# Each source reads something the customer proved, so the model can never choose the value.
module Captain::ParamSources
  # The message tells the model why the value is missing and what to do next
  class Unavailable < StandardError; end

  # Every source a parameter can name. A source answers .parse(name), #validate(account) and #resolve(conversation).
  ALL = [Captain::ParamSources::VerifiedEmail, Captain::ParamSources::VerifiedContactAttribute].freeze

  def self.parse(name)
    ALL.lazy.filter_map { |source| source.parse(name.to_s) }.first
  end
end
