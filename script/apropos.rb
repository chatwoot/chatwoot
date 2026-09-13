# ACCOUNT_ID=1 USER_ID=1 bundle exec rails runner script/apropos.rb
# A terminal client for the same persisted sessions used by Captain > Ask.
account = Account.find(ENV.fetch('ACCOUNT_ID'))
user = account.users.find(ENV.fetch('USER_ID'))
Captain::Apropos::Access.check!(account, user)
session = Captain::AproposSession.create!(account: account, user: user)
puts "Apropos session #{session.id}. Type /exit to leave."
loop do
  print '> '
  input = $stdin.gets
  break if input.nil? || input.strip == '/exit'
  next if input.strip.empty?

  session.update!(status: 'queued', messages: session.messages + [{ 'role' => 'user', 'content' => input.strip }])
  Captain::Apropos::TurnService.new(session).perform
  session.reload
  puts session.messages.last.fetch('content')
end
