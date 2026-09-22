# Run with: MONITOR_ACCOUNT_ID=123 bundle exec rails runner script/conversation_monitors/benchmark.rb
# Uses synthetic text only. Prints decisions and usage, never credentials.
require 'ostruct'

account = Account.find(ENV.fetch('MONITOR_ACCOUNT_ID'))
conditions = [
  'All conversations mentioning refunds',
  'All conversations related to WhatsApp BSUID',
  'All conversations related to automations from a self-hosted customer'
]
monitors = conditions.each_with_index.map do |condition, index|
  OpenStruct.new(id: index, condition: condition, model: ConversationMonitors::Configuration.model)
end
examples = JSON.parse(File.read(ARGV.first || File.join(__dir__, 'examples.json')))
results = examples.map do |example|
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  response = ConversationMonitors::JevClient.new(account_id: account.id).evaluate(state: example.fetch('state'), monitors: monitors)
  scores = monitors.map { |monitor| ConversationMonitors::JevClient.score(response.fetch('answers')[monitor.id.to_s]) }
  predictions = scores.map { |score| score >= ConversationMonitors::Configuration::THRESHOLD }
  { name: example.fetch('name'), expected: example.fetch('expected'), predictions: predictions, scores: scores,
    correct: predictions == example.fetch('expected'), model: response.fetch('model'), usage: response.fetch('usage'),
    seconds: (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started).round(3) }
end
puts JSON.pretty_generate(threshold: ConversationMonitors::Configuration::THRESHOLD, conditions: conditions, results: results)
exit(results.all? { |result| result[:correct] } ? 0 : 1)
