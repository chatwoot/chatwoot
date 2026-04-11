# LINE Core v2 and Canonical Identity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade Chatwoot's native LINE channel to SDK v2 and introduce a canonical 1:1 LINE identity model that can reuse existing `line_handle` contacts instead of creating duplicates.

**Architecture:** Keep the existing LINE channel schema and inbox wiring, but replace the v1 SDK entrypoints with explicit v2 clients and a v2 webhook parser. Add a small LINE webhook adapter and a dedicated contact resolver so native LINE can deterministically resolve `source_id`, `social_line_user_id`, and `custom_attributes.line_handle` before creating new contacts or conversations.

**Tech Stack:** Ruby on Rails, RSpec, ActiveRecord JSONB queries, `line-bot-api`, ActiveJob, ActiveStorage

---

## File map

- `Gemfile`
  - Pin `line-bot-api` first to the dual-stack `~> 1.30.0` release for migration, then to `~> 2.7` after all v1 references are gone.
- `Gemfile.lock`
  - Capture both gem upgrades.
- `app/models/channel/line.rb`
  - Expose SDK v2 messaging client, blob client, and webhook parser while preserving the existing persisted fields.
- `app/jobs/webhooks/line_events_job.rb`
  - Replace manual HMAC verification with the v2 webhook parser and feed normalized 1:1 events into the inbound service.
- `app/services/line/webhook_event_adapter.rb`
  - Normalize typed SDK webhook events into a small internal hash shape used by the LINE services.
- `app/services/line/contact_resolver_service.rb`
  - Resolve or create the correct contact/contact inbox by `source_id`, `social_line_user_id`, and `line_handle`, then mirror canonical LINE identity back onto the contact.
- `app/services/line/incoming_message_service.rb`
  - Consume normalized events, dedupe by LINE message id, fetch profile and media with v2 helpers, and delegate contact resolution.
- `app/services/line/send_on_line_service.rb`
  - Send outbound LINE messages through `PushMessageRequest` and v2 `push_message_with_http_info`.
- `spec/models/channel/line_spec.rb`
  - New model spec for v2 client helpers and parser.
- `spec/jobs/webhooks/line_events_job_spec.rb`
  - Update for parser-driven behavior and normalized events.
- `spec/controllers/webhooks/line_controller_spec.rb`
  - Assert raw body and `X-Line-Signature` are forwarded to the job.
- `spec/services/line/webhook_event_adapter_spec.rb`
  - New unit spec for supported and skipped webhook sources.
- `spec/services/line/contact_resolver_service_spec.rb`
  - New unit spec for deterministic identity resolution and enrichment.
- `spec/services/line/incoming_message_service_spec.rb`
  - Update for v2 profile/content fetches, dedup, and contact reuse.
- `spec/services/line/send_on_line_service_spec.rb`
  - Update for v2 push requests and HTTP status handling.

### Task 1: Introduce SDK v2 channel helpers on a dual-stack gem

**Files:**
- Modify: `Gemfile`
- Modify: `Gemfile.lock`
- Modify: `app/models/channel/line.rb`
- Create: `spec/models/channel/line_spec.rb`

- [ ] **Step 1: Write the failing model spec for the new v2 LINE helpers**

```ruby
require 'rails_helper'

RSpec.describe Channel::Line do
  describe '#messaging_api_client' do
    it 'builds a v2 messaging client with the stored channel access token' do
      channel = build(:channel_line, line_channel_token: 'token-123')

      client = channel.messaging_api_client

      expect(client).to be_a(Line::Bot::V2::MessagingApi::ApiClient)
    end
  end

  describe '#messaging_api_blob_client' do
    it 'builds a v2 blob client with the stored channel access token' do
      channel = build(:channel_line, line_channel_token: 'token-123')

      client = channel.messaging_api_blob_client

      expect(client).to be_a(Line::Bot::V2::MessagingApi::ApiBlobClient)
    end
  end

  describe '#webhook_parser' do
    it 'builds a v2 webhook parser with the stored channel secret' do
      channel = build(:channel_line, line_channel_secret: 'secret-123')

      parser = channel.webhook_parser

      expect(parser).to be_a(Line::Bot::V2::WebhookParser)
    end
  end
end
```

- [ ] **Step 2: Run the model spec to verify the helpers do not exist yet**

Run:

```bash
eval "$(rbenv init -)" && bundle exec rspec spec/models/channel/line_spec.rb
```

Expected:

```text
NoMethodError: undefined method `messaging_api_client'
```

- [ ] **Step 3: Upgrade the gem to the dual-stack migration release and add v2 helper methods**

Update `Gemfile`:

```ruby
gem 'facebook-messenger'
gem 'line-bot-api', '~> 1.30.0'
gem 'twilio-ruby'
```

Update `app/models/channel/line.rb`:

```ruby
class Channel::Line < ApplicationRecord
  include Channelable

  if Chatwoot.encryption_configured?
    encrypts :line_channel_secret
    encrypts :line_channel_token
  end

  self.table_name = 'channel_line'
  EDITABLE_ATTRS = [:line_channel_id, :line_channel_secret, :line_channel_token].freeze

  validates :line_channel_id, uniqueness: true, presence: true
  validates :line_channel_secret, presence: true
  validates :line_channel_token, presence: true

  def name
    'LINE'
  end

  def client
    messaging_api_client
  end

  def messaging_api_client
    @messaging_api_client ||= Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: line_channel_token,
      http_options: http_options
    )
  end

  def messaging_api_blob_client
    @messaging_api_blob_client ||= Line::Bot::V2::MessagingApi::ApiBlobClient.new(
      channel_access_token: line_channel_token,
      http_options: http_options
    )
  end

  def webhook_parser
    @webhook_parser ||= Line::Bot::V2::WebhookParser.new(
      channel_secret: line_channel_secret
    )
  end

  private

  def http_options
    return {} unless Rails.env.development?

    { verify_mode: OpenSSL::SSL::VERIFY_NONE }
  end
end
```

Run:

```bash
eval "$(rbenv init -)" && bundle update line-bot-api
```

Expected:

```text
Bundle updated!
```

- [ ] **Step 4: Run the model spec again and verify the v2 helpers work**

Run:

```bash
eval "$(rbenv init -)" && bundle exec rspec spec/models/channel/line_spec.rb
```

Expected:

```text
3 examples, 0 failures
```

- [ ] **Step 5: Commit the dual-stack helper layer**

```bash
git add Gemfile Gemfile.lock app/models/channel/line.rb spec/models/channel/line_spec.rb
git commit -m "refactor(line): add sdk v2 channel helpers"
```

### Task 2: Replace manual LINE webhook verification with the v2 parser

**Files:**
- Modify: `app/jobs/webhooks/line_events_job.rb`
- Create: `app/services/line/webhook_event_adapter.rb`
- Modify: `spec/jobs/webhooks/line_events_job_spec.rb`
- Modify: `spec/controllers/webhooks/line_controller_spec.rb`
- Create: `spec/services/line/webhook_event_adapter_spec.rb`

- [ ] **Step 1: Write the failing adapter and job specs**

Create `spec/services/line/webhook_event_adapter_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe Line::WebhookEventAdapter do
  describe '.normalize' do
    it 'normalizes a user text message event' do
      source = Struct.new(:user_id).new('U123')
      message = Struct.new(:id, :type, :text, :sticker_id, :file_name).new('mid-1', 'text', 'hello', nil, nil)
      event = Struct.new(:type, :source, :message).new('message', source, message)

      expect(described_class.normalize([event])).to eq(
        'events' => [
          {
            'type' => 'message',
            'source' => { 'userId' => 'U123' },
            'message' => { 'id' => 'mid-1', 'type' => 'text', 'text' => 'hello' }
          }
        ]
      )
    end

    it 'skips non-user sources' do
      source = Struct.new(:group_id).new('C123')
      message = Struct.new(:id, :type, :text).new('mid-1', 'text', 'hello')
      event = Struct.new(:type, :source, :message).new('message', source, message)

      expect(described_class.normalize([event])).to eq('events' => [])
    end
  end
end
```

Replace `spec/jobs/webhooks/line_events_job_spec.rb` with parser expectations:

```ruby
require 'rails_helper'

RSpec.describe Webhooks::LineEventsJob do
  let!(:line_channel) { create(:channel_line) }
  let(:parsed_event) { Struct.new(:type).new('message') }
  let(:normalized_payload) { { 'events' => [{ 'type' => 'message' }] } }

  it 'parses the webhook and forwards normalized events to the inbound service' do
    process_service = instance_double(Line::IncomingMessageService, perform: true)

    allow(line_channel).to receive(:webhook_parser).and_return(instance_double(Line::Bot::V2::WebhookParser, parse: [parsed_event]))
    allow(Line::WebhookEventAdapter).to receive(:normalize).with([parsed_event]).and_return(normalized_payload)
    allow(Line::IncomingMessageService).to receive(:new).and_return(process_service)

    described_class.perform_now(
      params: { 'line_channel_id' => line_channel.line_channel_id },
      post_body: '{"events":[]}',
      signature: 'sig'
    )

    expect(Line::IncomingMessageService).to have_received(:new).with(
      inbox: line_channel.inbox,
      params: normalized_payload.with_indifferent_access
    )
  end
end
```

Tighten `spec/controllers/webhooks/line_controller_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe 'Webhooks::LineController', type: :request do
  describe 'POST /webhooks/line/:line_channel_id' do
    it 'passes the raw body and signature header into the job' do
      allow(Webhooks::LineEventsJob).to receive(:perform_later)

      post '/webhooks/line/line-channel-id',
           params: '{"events":[]}',
           headers: {
             'CONTENT_TYPE' => 'application/json',
             'X-Line-Signature' => 'sig-123'
           }

      expect(Webhooks::LineEventsJob).to have_received(:perform_later).with(
        params: hash_including('line_channel_id' => 'line-channel-id'),
        signature: 'sig-123',
        post_body: '{"events":[]}'
      )
    end
  end
end
```

- [ ] **Step 2: Run the webhook specs to watch them fail on the missing adapter and old job behavior**

Run:

```bash
eval "$(rbenv init -)" && bundle exec rspec \
  spec/controllers/webhooks/line_controller_spec.rb \
  spec/jobs/webhooks/line_events_job_spec.rb \
  spec/services/line/webhook_event_adapter_spec.rb
```

Expected:

```text
NameError: uninitialized constant Line::WebhookEventAdapter
```

- [ ] **Step 3: Implement the webhook adapter and parser-driven job**

Create `app/services/line/webhook_event_adapter.rb`:

```ruby
class Line::WebhookEventAdapter
  class << self
    def normalize(events)
      {
        'events' => events.filter_map { |event| normalize_event(event) }
      }
    end

    private

    def normalize_event(event)
      return unless event.type == 'message'
      return unless event.source.respond_to?(:user_id)

      {
        'type' => event.type,
        'source' => { 'userId' => event.source.user_id },
        'message' => normalize_message(event.message)
      }
    end

    def normalize_message(message)
      payload = {
        'id' => message.id.to_s,
        'type' => message.type
      }

      payload['text'] = message.text if message.respond_to?(:text)
      payload['stickerId'] = message.sticker_id if message.respond_to?(:sticker_id)
      payload['fileName'] = message.file_name if message.respond_to?(:file_name)
      payload
    end
  end
end
```

Update `app/jobs/webhooks/line_events_job.rb`:

```ruby
class Webhooks::LineEventsJob < ApplicationJob
  queue_as :default

  def perform(params: {}, signature: '', post_body: '')
    @params = params.with_indifferent_access
    @channel = Channel::Line.find_by(line_channel_id: @params[:line_channel_id])
    return unless @channel

    events = @channel.webhook_parser.parse(body: post_body, signature: signature)
    normalized_payload = Line::WebhookEventAdapter.normalize(events)

    Line::IncomingMessageService.new(
      inbox: @channel.inbox,
      params: normalized_payload.with_indifferent_access
    ).perform
  rescue Line::Bot::V2::WebhookParser::InvalidSignatureError
    nil
  end
end
```

- [ ] **Step 4: Run the webhook specs again**

Run:

```bash
eval "$(rbenv init -)" && bundle exec rspec \
  spec/controllers/webhooks/line_controller_spec.rb \
  spec/jobs/webhooks/line_events_job_spec.rb \
  spec/services/line/webhook_event_adapter_spec.rb
```

Expected:

```text
5 examples, 0 failures
```

- [ ] **Step 5: Commit the parser migration layer**

```bash
git add \
  app/jobs/webhooks/line_events_job.rb \
  app/services/line/webhook_event_adapter.rb \
  spec/controllers/webhooks/line_controller_spec.rb \
  spec/jobs/webhooks/line_events_job_spec.rb \
  spec/services/line/webhook_event_adapter_spec.rb
git commit -m "refactor(line): parse webhooks with sdk v2"
```

### Task 3: Add deterministic LINE contact resolution and enrichment

**Files:**
- Create: `app/services/line/contact_resolver_service.rb`
- Create: `spec/services/line/contact_resolver_service_spec.rb`

- [ ] **Step 1: Write the failing resolver spec for source_id, social_line_user_id, and line_handle matching**

Create `spec/services/line/contact_resolver_service_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe Line::ContactResolverService do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_line, account: account) }
  let(:inbox) { channel.inbox }
  let(:profile) do
    Struct.new(:user_id, :display_name, :picture_url).new(
      'U-line-123',
      'LINE Jane',
      'https://example.com/jane.png'
    )
  end

  it 'reuses an existing contact inbox by source_id' do
    contact_inbox = create(:contact_inbox, inbox: inbox, source_id: 'U-line-123')

    resolved = described_class.new(inbox: inbox, profile: profile).perform

    expect(resolved.id).to eq(contact_inbox.id)
  end

  it 'reuses an existing contact matched by social_line_user_id' do
    contact = create(:contact, account: account, additional_attributes: { 'social_line_user_id' => 'U-line-123' })

    resolved = described_class.new(inbox: inbox, profile: profile).perform

    expect(resolved.contact_id).to eq(contact.id)
    expect(resolved.source_id).to eq('U-line-123')
    expect(contact.reload.custom_attributes['line_handle']).to eq('U-line-123')
  end

  it 'reuses an existing contact matched by custom_attributes line_handle' do
    contact = create(:contact, account: account, custom_attributes: { 'line_handle' => 'U-line-123' })

    resolved = described_class.new(inbox: inbox, profile: profile).perform

    expect(resolved.contact_id).to eq(contact.id)
    expect(contact.reload.additional_attributes['social_line_user_id']).to eq('U-line-123')
  end

  it 'creates a new contact and contact inbox when no match exists' do
    resolved = described_class.new(inbox: inbox, profile: profile).perform

    expect(resolved.contact.custom_attributes['line_handle']).to eq('U-line-123')
    expect(resolved.contact.additional_attributes['social_line_user_id']).to eq('U-line-123')
  end
end
```

- [ ] **Step 2: Run the resolver spec to confirm the service does not exist yet**

Run:

```bash
eval "$(rbenv init -)" && bundle exec rspec spec/services/line/contact_resolver_service_spec.rb
```

Expected:

```text
NameError: uninitialized constant Line::ContactResolverService
```

- [ ] **Step 3: Implement the resolver with explicit lookup precedence and enrichment**

Create `app/services/line/contact_resolver_service.rb`:

```ruby
class Line::ContactResolverService
  class AmbiguousContactMatchError < StandardError; end

  pattr_initialize [:inbox!, :profile!]

  def perform
    existing_contact_inbox || contact_inbox_for_existing_contact || create_contact_inbox_with_contact
  end

  private

  def existing_contact_inbox
    @existing_contact_inbox ||= inbox.contact_inboxes.find_by(source_id: line_user_id)
  end

  def contact_inbox_for_existing_contact
    contact = find_contact_by_social_line_user_id || find_contact_by_line_handle
    return unless contact

    enrich_contact(contact)
    ContactInboxBuilder.new(contact: contact, inbox: inbox, source_id: line_user_id).perform
  end

  def create_contact_inbox_with_contact
    ContactInboxWithContactBuilder.new(
      inbox: inbox,
      source_id: line_user_id,
      contact_attributes: {
        name: profile.display_name,
        avatar_url: profile.picture_url,
        additional_attributes: { social_line_user_id: line_user_id },
        custom_attributes: { line_handle: line_user_id }
      }
    ).perform
  end

  def enrich_contact(contact)
    contact.update!(
      additional_attributes: contact.additional_attributes.merge('social_line_user_id' => line_user_id),
      custom_attributes: contact.custom_attributes.merge('line_handle' => line_user_id),
      name: contact.name.presence || profile.display_name
    )
  end

  def find_contact_by_social_line_user_id
    find_single_contact("additional_attributes ->> 'social_line_user_id' = ?", line_user_id)
  end

  def find_contact_by_line_handle
    find_single_contact("custom_attributes ->> 'line_handle' = ?", line_user_id)
  end

  def find_single_contact(condition, value)
    matches = inbox.account.contacts.where(condition, value).limit(2).to_a
    raise AmbiguousContactMatchError, line_user_id if matches.size > 1

    matches.first
  end

  def line_user_id
    profile.user_id
  end
end
```

- [ ] **Step 4: Run the resolver spec again**

Run:

```bash
eval "$(rbenv init -)" && bundle exec rspec spec/services/line/contact_resolver_service_spec.rb
```

Expected:

```text
4 examples, 0 failures
```

- [ ] **Step 5: Commit the canonical identity resolver**

```bash
git add app/services/line/contact_resolver_service.rb spec/services/line/contact_resolver_service_spec.rb
git commit -m "feat(line): resolve contacts by canonical line identity"
```

### Task 4: Migrate inbound LINE processing to v2 clients and idempotent 1:1 behavior

**Files:**
- Modify: `app/services/line/incoming_message_service.rb`
- Modify: `spec/services/line/incoming_message_service_spec.rb`

- [ ] **Step 1: Add failing inbound specs for contact reuse and duplicate message suppression**

Append these examples to `spec/services/line/incoming_message_service_spec.rb`:

```ruby
it 'reuses an existing contact matched by line_handle' do
  create(:contact, account: line_channel.account, custom_attributes: { 'line_handle' => 'U4af4980629' })

  described_class.new(inbox: line_channel.inbox, params: params).perform

  expect(line_channel.inbox.contacts.count).to eq(1)
  expect(line_channel.inbox.contacts.first.additional_attributes['social_line_user_id']).to eq('U4af4980629')
end

it 'does not create a duplicate message when the same line message id is received twice' do
  described_class.new(inbox: line_channel.inbox, params: params).perform
  described_class.new(inbox: line_channel.inbox, params: params).perform

  expect(line_channel.inbox.messages.count).to eq(1)
end
```

Replace the v1 client stubs in the existing spec with v2 helper stubs:

```ruby
let(:messaging_client) { instance_double(Line::Bot::V2::MessagingApi::ApiClient) }
let(:blob_client) { instance_double(Line::Bot::V2::MessagingApi::ApiBlobClient) }
let(:profile) do
  Struct.new(:display_name, :user_id, :picture_url).new(
    'LINE Test',
    'U4af4980629',
    'https://test.com'
  )
end

before do
  allow(line_channel).to receive(:messaging_api_client).and_return(messaging_client)
  allow(line_channel).to receive(:messaging_api_blob_client).and_return(blob_client)
  allow(messaging_client).to receive(:get_profile).with(user_id: 'U4af4980629').and_return(profile)
end
```

For media examples, switch to:

```ruby
allow(blob_client).to receive(:get_message_content_with_http_info).and_return(
  [file.read, 200, { 'content-type' => 'image/png' }]
)
```

- [ ] **Step 2: Run the inbound service spec and capture the failures**

Run:

```bash
eval "$(rbenv init -)" && bundle exec rspec spec/services/line/incoming_message_service_spec.rb
```

Expected:

```text
Failures for missing messaging_api_client/messaging_api_blob_client usage and duplicate message handling
```

- [ ] **Step 3: Update the inbound service to use the resolver, v2 profile client, v2 blob client, and duplicate suppression**

Update `app/services/line/incoming_message_service.rb`:

```ruby
class Line::IncomingMessageService
  include ::FileTypeHelper
  pattr_initialize [:inbox!, :params!]
  LINE_STICKER_IMAGE_URL = 'https://stickershop.line-scdn.net/stickershop/v1/sticker/%s/android/sticker.png'.freeze

  def perform
    return if params[:events].blank?

    params[:events].each do |event|
      next unless event_type_message?(event)
      next if duplicate_message?(event)

      profile = inbox.channel.messaging_api_client.get_profile(user_id: event.dig('source', 'userId'))
      next if profile.blank? || profile.user_id.blank?

      @contact_inbox = Line::ContactResolverService.new(inbox: inbox, profile: profile).perform
      @contact = @contact_inbox.contact
      @conversation = find_or_create_conversation
      @message = build_message(event)

      attach_files(event['message'])
      @message.save!
    end
  end

  private

  def duplicate_message?(event)
    inbox.messages.exists?(source_id: event.dig('message', 'id').to_s)
  end

  def build_message(event)
    @conversation.messages.build(
      content: message_content(event),
      account_id: inbox.account_id,
      content_type: message_content_type(event),
      inbox_id: inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: event.dig('message', 'id').to_s
    )
  end

  def find_or_create_conversation
    conversation = if inbox.lock_to_single_conversation
                     @contact_inbox.conversations.last
                   else
                     @contact_inbox.conversations.where.not(status: :resolved).last
                   end

    conversation || Conversation.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id
    )
  end

  def attach_files(message)
    return unless %w[video audio image file].include?(message['type'])

    body, status, headers = inbox.channel.messaging_api_blob_client.get_message_content_with_http_info(
      message_id: message['id']
    )
    return unless status == 200

    content_type = headers['content-type']
    extension = content_type&.split('/')&.last || 'bin'
    file_name = message['fileName'] || "media-#{message['id']}.#{extension}"

    temp_file = Tempfile.new(file_name)
    temp_file.binmode
    temp_file << body
    temp_file.rewind

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: file_type(content_type),
      file: {
        io: temp_file,
        filename: file_name,
        content_type: content_type
      }
    )
  end
end
```

- [ ] **Step 4: Run the inbound service spec again**

Run:

```bash
eval "$(rbenv init -)" && bundle exec rspec spec/services/line/incoming_message_service_spec.rb
```

Expected:

```text
All LINE inbound examples pass, including line_handle reuse and duplicate suppression
```

- [ ] **Step 5: Commit the inbound migration**

```bash
git add app/services/line/incoming_message_service.rb spec/services/line/incoming_message_service_spec.rb
git commit -m "feat(line): migrate inbound processing to sdk v2"
```

### Task 5: Migrate outbound LINE sends to v2 push requests

**Files:**
- Modify: `app/services/line/send_on_line_service.rb`
- Modify: `spec/services/line/send_on_line_service_spec.rb`

- [ ] **Step 1: Update the outbound spec to expect `PushMessageRequest` and v2 HTTP info handling**

Replace the v1 client expectation in `spec/services/line/send_on_line_service_spec.rb`:

```ruby
let(:messaging_client) { instance_double(Line::Bot::V2::MessagingApi::ApiClient) }

before do
  allow(line_channel).to receive(:messaging_api_client).and_return(messaging_client)
end

it 'pushes a v2 request object to the contact inbox source id' do
  allow(messaging_client).to receive(:push_message_with_http_info).and_return([{}, 200, {}])

  described_class.new(message: message).perform

  expect(messaging_client).to have_received(:push_message_with_http_info) do |push_message_request:|
    expect(push_message_request).to be_a(Line::Bot::V2::MessagingApi::PushMessageRequest)
    expect(push_message_request.to).to eq(message.conversation.contact_inbox.source_id)
    expect(push_message_request.messages.first.text).to eq('test')
  end
end
```

Update failure examples to return:

```ruby
allow(messaging_client).to receive(:push_message_with_http_info).and_return(
  ['{"message":"The request was invalid"}', 400, {}]
)
```

- [ ] **Step 2: Run the outbound spec to observe failures from the old v1 send path**

Run:

```bash
eval "$(rbenv init -)" && bundle exec rspec spec/services/line/send_on_line_service_spec.rb
```

Expected:

```text
Failures because the service still calls `push_message`
```

- [ ] **Step 3: Implement the v2 push request path**

Update `app/services/line/send_on_line_service.rb`:

```ruby
class Line::SendOnLineService < Base::SendOnChannelService
  private

  def channel_class
    Channel::Line
  end

  def perform_reply
    response_body, status_code, _headers = channel.messaging_api_client.push_message_with_http_info(
      push_message_request: Line::Bot::V2::MessagingApi::PushMessageRequest.new(
        to: message.conversation.contact_inbox.source_id,
        messages: Array.wrap(build_payload)
      )
    )

    if status_code == 200
      Messages::StatusUpdateService.new(message, 'delivered').perform
    else
      parsed_json = response_body.is_a?(String) ? JSON.parse(response_body) : response_body
      Messages::StatusUpdateService.new(message, 'failed', external_error(parsed_json)).perform
    end
  end

  def text_message
    Line::Bot::V2::MessagingApi::TextMessage.new(
      text: message.outgoing_content
    )
  end

  def build_input_select_payload
    {
      type: 'flex',
      altText: message.content,
      contents: {
        type: 'bubble',
        body: {
          type: 'box',
          layout: 'vertical',
          contents: [
            {
              type: 'text',
              text: message.content,
              wrap: true
            },
            *input_select_to_button
          ]
        }
      }
    }
  end
end
```

- [ ] **Step 4: Run the outbound spec again**

Run:

```bash
eval "$(rbenv init -)" && bundle exec rspec spec/services/line/send_on_line_service_spec.rb
```

Expected:

```text
All LINE send examples pass with the v2 push request path
```

- [ ] **Step 5: Commit the outbound migration**

```bash
git add app/services/line/send_on_line_service.rb spec/services/line/send_on_line_service_spec.rb
git commit -m "refactor(line): send outbound messages via sdk v2"
```

### Task 6: Remove remaining v1 dependencies and pin the gem to v2.x

**Files:**
- Modify: `Gemfile`
- Modify: `Gemfile.lock`
- Verify: `app/models/channel/line.rb`
- Verify: `app/jobs/webhooks/line_events_job.rb`
- Verify: `app/services/line/incoming_message_service.rb`
- Verify: `app/services/line/send_on_line_service.rb`

- [ ] **Step 1: Write the failing regression check that ensures no code path still references `Line::Bot::Client`**

Run:

```bash
rg -n "Line::Bot::Client|Line::Bot::Event::MessageType" app spec
```

Expected before the change:

```text
Matches in the LINE channel files and specs
```

- [ ] **Step 2: Update the gem pin from the dual-stack migration version to the current v2 line**

Update `Gemfile`:

```ruby
gem 'facebook-messenger'
gem 'line-bot-api', '~> 2.7'
gem 'twilio-ruby'
```

Run:

```bash
eval "$(rbenv init -)" && bundle update line-bot-api
```

Expected:

```text
line-bot-api (2.7.0)
```

- [ ] **Step 3: Remove any last v1 constants from specs or implementation**

Typical replacement cleanup:

```ruby
# Replace this
Line::Bot::Event::MessageType::Image

# With the normalized payload string values already produced by the adapter
'image'
```

And ensure `client` compatibility is no longer used in the LINE code:

```bash
rg -n "channel\\.client|Line::Bot::Client|Line::Bot::Event::MessageType" app/services/line app/jobs/webhooks spec/services/line spec/jobs/webhooks
```

Expected:

```text
No matches
```

- [ ] **Step 4: Run the full focused Phase 1 verification suite**

Run:

```bash
eval "$(rbenv init -)" && bundle exec rspec \
  spec/models/channel/line_spec.rb \
  spec/controllers/webhooks/line_controller_spec.rb \
  spec/jobs/webhooks/line_events_job_spec.rb \
  spec/services/line/webhook_event_adapter_spec.rb \
  spec/services/line/contact_resolver_service_spec.rb \
  spec/services/line/incoming_message_service_spec.rb \
  spec/services/line/send_on_line_service_spec.rb
```

Expected:

```text
All focused LINE phase 1 specs pass
```

- [ ] **Step 5: Commit the final v2-only state**

```bash
git add Gemfile Gemfile.lock app/models/channel/line.rb app/jobs/webhooks/line_events_job.rb app/services/line spec/models/channel/line_spec.rb spec/controllers/webhooks/line_controller_spec.rb spec/jobs/webhooks/line_events_job_spec.rb spec/services/line
git commit -m "feat(line): complete sdk v2 identity migration"
```

## Self-review

- Spec coverage:
  - SDK v2 client migration: covered in Tasks 1, 2, 4, 5, and 6.
  - Canonical identity resolution and `line_handle` mirroring: covered in Tasks 3 and 4.
  - Duplicate suppression: covered in Task 4.
  - No PNP or groups in this phase: intentionally excluded.
- Placeholder scan:
  - No `TBD`, `TODO`, or deferred implementation placeholders are used inside task steps.
- Type consistency:
  - The plan consistently uses `messaging_api_client`, `messaging_api_blob_client`, `webhook_parser`, `line_handle`, and `social_line_user_id`.

