# examples version

@account_sid = 'ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
@auth_token = 'yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy'
# set up a client
@client = Twilio::REST::Client.new(@account_sid, @auth_token)

################ ACCOUNTS ################

# shortcut to grab your account object (account_sid is inferred from the client's auth credentials)
@account = @client.api.account

# list your (sub)accounts
@accounts = @client.api.accounts.each do |account|
  puts(account)
end

# grab an account instance resource if you know the sid
@account = @client.api.accounts(account_sid).fetch
puts(@account.friendly_name)

# update an account's friendly name
@client.api.accounts(account_sid).update(friendly_name: 'A Fabulous Friendly Name')

################ CALLS ################

# print a list of calls (all parameters optional)
@client.calls.list(limit: 10, start_time: '2010-09-01').each do |call|
  puts call.sid
end

# get a particular call and list its recording urls
@client.calls('CAXXXXXXX').recordings.each do |r|
  puts r.wav
end

# make a new outgoing call. returns a call object just like calls.get
@call = @client.calls.create(
  from: '+14159341234',
  to: '+18004567890',
  url: 'http://example.com/call-handler'
)

# cancel the call if not already in progress
@client.calls(@call.sid).update(status: 'canceled')

# redirect and then terminate a call
@call = client.calls('CAXXXXXXX')
@call.update(url: 'http://example.com/call-redirect')
@call.update(status: 'completed')

################ SMS MESSAGES ################

@client.messages.list(date_sent: '2010-09-01').each do |message|
  puts message.date_created
end

# print a particular sms message
puts @client.messages('SMXXXXXXXX').fetch.body

# send an sms
@client.messages.create(
  from: '+14159341234',
  to: '+16105557069',
  body: 'Hey there!'
)

# send an mms
@client.messages.create(
  from: '+14159341234',
  to: '+16105557069',
  media_url: 'http://example.com/media.png'
)

################ PHONE NUMBERS ################

# get a list of supported country codes
@client.available_phone_numbers.list

# print some available numbers
@client.available_phone_numbers('US').local.list.each do |num|
  puts num
end

@numbers = @client.available_phone_numbers('US').local.list(area_code: '908')
@numbers.each { |num| puts num.phone_number }

# buy the first one
@client.incoming_phone_numbers.create(phone_number: @numbers[0].phone_number)

# update an existing phone number's voice url
@client.incoming_phone_numbers('PNxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx').update(voice_url: 'http://example.com/voice')

# decommission an existing phone number
numbers = @client.incoming_phone_numbers.list(friendly_name: 'A Fabulous Friendly Name')
number = numbers[0].sid
@client.incoming_phone_numbers(number).delete

################ CONFERENCES  ################

# get a particular conference's participants object and stash it
conference = @client.conferences('CFxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx').fetch
@participants = conference.participants

# list participants
@participants.each do |p|
  puts p.sid
end

# update a conference participant
@client
  .conferences('CFxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx')
  .participants('CAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx')
  .update(muted: 'true')

################ QUEUES ###################

# create a new queue
@queue = @client.queues.create(friendly_name: 'MyQueue', max_size: 50)

# get a list of queues for this account
@queues = @client.queues.list

# get a particular queue and its members
@queue = @client.queues('QQxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx').fetch
@members = @queue.members

# list members
@members.list.each do |m|
  puts m.wait_time
end

# dequeue a particular user and run twiml at a specific url
@client
  .queues('QQxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx')
  .members('CAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx')
  .update(url: 'http://myapp.com/deque', method: 'POST')
