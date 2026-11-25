require 'rails_helper'

RSpec.describe Avatar::AvatarFromUrlJob do
  let(:valid_url) { 'https://example.com/avatar.png' }

  before do
    allow(Resolv).to receive(:getaddresses).and_call_original
    allow(Resolv).to receive(:getaddresses).with('example.com').and_return(['93.184.216.34'])
  end

  it 'enqueues the job' do
    contact = create(:contact)
    expect { described_class.perform_later(contact, 'https://example.com/avatar.png') }
      .to have_enqueued_job(described_class).on_queue('purgable')
  end

  # A picture removed between the URL being resolved and this job running cannot be seen
  # from inside it: an avatarable with nothing attached is both "just purged" and "never
  # had one", and filling the second is the job's whole purpose. The date the caller
  # stamps is what separates them.
  context 'when the picture was removed while the job waited' do
    let(:avatarable) { create(:contact) }

    before do
      stub_request(:get, valid_url).to_return(
        status: 200,
        body: File.read(Rails.root.join('spec/assets/avatar.png')),
        headers: { 'Content-Type' => 'image/png' }
      )
    end

    it 'does not put the removed picture back' do
      resolved_at = 1.minute.ago.iso8601
      Whatsapp::Session::AvatarSync.remove(avatarable)

      described_class.perform_now(avatarable, valid_url, resolved_at: resolved_at)

      expect(avatarable.reload.avatar).not_to be_attached
    end

    it 'attaches a picture resolved after the removal' do
      Whatsapp::Session::AvatarSync.remove(avatarable)

      described_class.perform_now(avatarable, valid_url, resolved_at: 1.minute.from_now.iso8601)

      expect(avatarable.reload.avatar).to be_attached
    end

    # Every caller that does not date its URL keeps the behaviour it had.
    it 'attaches when the caller did not date the url' do
      Whatsapp::Session::AvatarSync.remove(avatarable)

      described_class.perform_now(avatarable, valid_url)

      expect(avatarable.reload.avatar).to be_attached
    end
  end

  context 'with rate-limited avatarable (Contact)' do
    let(:avatarable) { create(:contact) }

    it 'attaches and updates sync attributes' do
      stub_request(:get, valid_url)
        .to_return(
          status: 200,
          body: File.read(Rails.root.join('spec/assets/avatar.png')),
          headers: { 'Content-Type' => 'image/png' }
        )

      described_class.perform_now(avatarable, valid_url)
      avatarable.reload
      expect(avatarable.avatar).to be_attached
      expect(avatarable.additional_attributes['avatar_url_hash']).to eq(Digest::SHA256.hexdigest(valid_url))
      expect(avatarable.additional_attributes['last_avatar_sync_at']).to be_present
    end

    it 'attaches webp avatars and updates sync attributes' do
      webp_url = 'https://example.com/avatar.webp'

      stub_request(:get, webp_url)
        .to_return(
          status: 200,
          body: File.read(Rails.root.join('spec/assets/avatar.png')),
          headers: { 'Content-Type' => 'image/webp' }
        )

      described_class.perform_now(avatarable, webp_url)
      avatarable.reload

      expect(avatarable.avatar).to be_attached
      expect(avatarable.additional_attributes['avatar_url_hash']).to eq(Digest::SHA256.hexdigest(webp_url))
      expect(avatarable.additional_attributes['last_avatar_sync_at']).to be_present
    end

    it 'attaches avatars with parameterized content type headers' do
      parameterized_url = 'https://example.com/avatar-parameterized.png'

      stub_request(:get, parameterized_url)
        .to_return(
          status: 200,
          body: File.read(Rails.root.join('spec/assets/avatar.png')),
          headers: { 'Content-Type' => 'IMAGE/PNG; charset=binary' }
        )

      described_class.perform_now(avatarable, parameterized_url)
      avatarable.reload

      expect(avatarable.avatar).to be_attached
      expect(avatarable.avatar.blob.content_type).to eq('image/png')
      expect(avatarable.additional_attributes['avatar_url_hash']).to eq(Digest::SHA256.hexdigest(parameterized_url))
    end

    it 'attaches avatars from URLs with embedded basic auth credentials' do
      authenticated_url = 'https://user:pass@example.com/avatar-authenticated.png'

      stub_request(:get, 'https://example.com/avatar-authenticated.png')
        .with(headers: { 'Authorization' => 'Basic dXNlcjpwYXNz' })
        .to_return(
          status: 200,
          body: File.read(Rails.root.join('spec/assets/avatar.png')),
          headers: { 'Content-Type' => 'image/png' }
        )

      described_class.perform_now(avatarable, authenticated_url)
      avatarable.reload

      expect(avatarable.avatar).to be_attached
      expect(avatarable.additional_attributes['avatar_url_hash']).to eq(Digest::SHA256.hexdigest(authenticated_url))
    end

    # A job that never downloaded must not move the markers. It used to stamp both, which both
    # extended its own rate-limit window and recorded a URL it had not fetched as synced.
    it 'returns early when rate limited, leaving the markers where they were' do
      ts = 30.seconds.ago.iso8601
      avatarable.update!(additional_attributes: { 'last_avatar_sync_at' => ts })

      stub_request(:get, valid_url)
        .to_return(
          status: 200,
          body: File.read(Rails.root.join('spec/assets/avatar.png')),
          headers: { 'Content-Type' => 'image/png' }
        )

      described_class.perform_now(avatarable, valid_url)
      avatarable.reload
      expect(avatarable.avatar).not_to be_attached
      expect(avatarable.additional_attributes['last_avatar_sync_at']).to eq(ts)
      expect(avatarable.additional_attributes['avatar_url_hash']).to be_nil
      expect(WebMock).not_to have_requested(:get, valid_url)
    end

    # The shortest path to the same loss, and it needs no removal at all: a contact who changes
    # their photo twice inside one window. The first job fetches, the second is turned away by the
    # window, and while it stamped on the way out the second URL was recorded as synced without a
    # byte having been read. Found by a parallel session working the same issue.
    it 'still fetches the second picture when two arrive inside one window' do
      second_url = 'https://example.com/avatar-2.png'
      [valid_url, second_url].each do |url|
        stub_request(:get, url).to_return(
          status: 200,
          body: File.read(Rails.root.join('spec/assets/avatar.png')),
          headers: { 'Content-Type' => 'image/png' }
        )
      end

      described_class.perform_now(avatarable, valid_url)
      described_class.perform_now(avatarable, second_url)

      travel_to((described_class::RATE_LIMIT_WINDOW + 1.second).from_now) do
        described_class.perform_now(avatarable, second_url)
      end

      expect(WebMock).to have_requested(:get, second_url)
      expect(avatarable.reload.additional_attributes['avatar_url_hash'])
        .to eq(Digest::SHA256.hexdigest(second_url))
    end

    it 'returns early when hash unchanged, without opening a new rate-limit window' do
      avatarable.update!(additional_attributes: { 'avatar_url_hash' => Digest::SHA256.hexdigest(valid_url) })

      stub_request(:get, valid_url)
        .to_return(
          status: 200,
          body: File.read(Rails.root.join('spec/assets/avatar.png')),
          headers: { 'Content-Type' => 'image/png' }
        )

      described_class.perform_now(avatarable, valid_url)
      expect(avatarable.avatar).not_to be_attached
      avatarable.reload
      expect(avatarable.additional_attributes['last_avatar_sync_at']).to be_nil
      expect(avatarable.additional_attributes['avatar_url_hash']).to eq(Digest::SHA256.hexdigest(valid_url))
      expect(WebMock).not_to have_requested(:get, valid_url)
    end

    # A URL the job refuses to even parse is not a sync. Stamping it opened a rate-limit window
    # that a good URL arriving seconds later would then be turned away by.
    it 'leaves the markers alone when the URL is invalid' do
      invalid_url = 'invalid_url'
      described_class.perform_now(avatarable, invalid_url)
      avatarable.reload
      expect(avatarable.avatar).not_to be_attached
      expect(avatarable.additional_attributes['last_avatar_sync_at']).to be_nil
      expect(avatarable.additional_attributes['avatar_url_hash']).to be_nil
    end

    it 'updates sync attributes when file download is valid but content type is unsupported' do
      stub_request(:get, valid_url)
        .to_return(
          status: 200,
          body: '<invalid>content</invalid>',
          headers: { 'Content-Type' => 'application/xml' }
        )

      described_class.perform_now(avatarable, valid_url)
      avatarable.reload

      expect(avatarable.avatar).not_to be_attached
      expect(avatarable.additional_attributes['last_avatar_sync_at']).to be_present
      expect(avatarable.additional_attributes['avatar_url_hash']).to eq(Digest::SHA256.hexdigest(valid_url))
    end

    it 'updates sync attributes when the avatar URL is blocked by SSRF protection' do
      blocked_url = 'http://127.0.0.1/avatar.png'

      expect do
        described_class.perform_now(avatarable, blocked_url)
      end.not_to raise_error

      avatarable.reload
      expect(avatarable.avatar).not_to be_attached
      expect(avatarable.additional_attributes['last_avatar_sync_at']).to be_present
      expect(avatarable.additional_attributes['avatar_url_hash']).to eq(Digest::SHA256.hexdigest(blocked_url))
    end
  end

  # An infrastructure error is not an answer about the URL. The job will be retried, and a marker
  # written on the way out would make the retry skip the download it exists to perform.
  it 'leaves the markers alone when an error other than a fetch error escapes' do
    contact = create(:contact)
    allow(SafeFetch).to receive(:fetch).and_raise(ActiveRecord::ConnectionNotEstablished)

    expect { described_class.perform_now(contact, valid_url) }.to raise_error(ActiveRecord::ConnectionNotEstablished)

    contact.reload
    expect(contact.additional_attributes['last_avatar_sync_at']).to be_nil
    expect(contact.additional_attributes['avatar_url_hash']).to be_nil
  end

  # `additional_attributes` is one JSON column that several writers share, and the job used to
  # persist a copy it had read before the download. The defect is a stale in-memory snapshot
  # rather than a database race, so forcing it needs no threads: write through a second instance
  # while the fetch is in flight, and the job's own copy is already behind.
  context 'when something else writes to the same column during the download' do
    let(:contact) { create(:contact, additional_attributes: { 'city' => 'Uberlandia' }) }

    def write_during_download(key, value)
      allow(SafeFetch).to receive(:fetch) do |_url, **_opts, &block|
        other = Contact.find(contact.id)
        # Deliberately not the shared primitive: this stands in for a writer that does not use
        # it, which is the whole hazard under test.
        other.update_columns(additional_attributes: (other.additional_attributes || {}).merge(key => value)) # rubocop:disable Rails/SkipsModelValidations
        block.call(
          SafeFetch::Result.new(
            tempfile: File.open(Rails.root.join('spec/assets/avatar.png')),
            filename: 'avatar.png',
            content_type: 'image/png'
          )
        )
      end
    end

    # The one that matters most: `avatar_removed_at` is what `superseded?` reads, so erasing it
    # un-does a removal and lets the next superseded job put the deleted photo back. It is the
    # outcome of #504 reached by another door.
    it 'keeps a removal that landed while the picture was downloading' do
      write_during_download(Whatsapp::Session::AvatarSync::REMOVED_AT, 1.second.ago.iso8601)

      described_class.perform_now(contact, valid_url)

      expect(contact.reload.additional_attributes).to include(Whatsapp::Session::AvatarSync::REMOVED_AT)
    end

    it 'keeps an unrelated key written during the download' do
      write_during_download('country', 'BR')

      described_class.perform_now(contact, valid_url)

      expect(contact.reload.additional_attributes).to include('country' => 'BR', 'city' => 'Uberlandia')
    end

    it 'still writes its own markers' do
      write_during_download('country', 'BR')

      described_class.perform_now(contact, valid_url)

      expect(contact.reload.additional_attributes)
        .to include('avatar_url_hash' => Digest::SHA256.hexdigest(valid_url))
    end
  end

  # The sequence from #504. Each step looks harmless on its own, and the cost only shows when
  # they run in order: the new picture never arrives, and nothing retries until the contact
  # changes their photo again.
  context 'when a superseded job runs just before the job that carries the new picture' do
    let(:contact) { create(:contact) }
    let(:old_url) { 'https://example.com/old-avatar.png' }
    let(:new_url) { 'https://example.com/new-avatar.png' }

    before do
      [old_url, new_url].each do |url|
        stub_request(:get, url).to_return(
          status: 200,
          body: File.read(Rails.root.join('spec/assets/avatar.png')),
          headers: { 'Content-Type' => 'image/png' }
        )
      end
    end

    it 'still attaches the new picture' do
      resolved_at = 1.minute.ago.iso8601
      Whatsapp::Session::AvatarSync.remove(contact)

      # The job carrying the URL from before the removal. It must not download, and must not
      # leave a marker that the next job will be measured against.
      described_class.perform_now(contact, old_url, resolved_at: resolved_at)
      described_class.perform_now(contact, new_url, resolved_at: Time.current.iso8601)

      expect(contact.reload.avatar).to be_attached
      expect(WebMock).to have_requested(:get, new_url)
      expect(WebMock).not_to have_requested(:get, old_url)
      expect(contact.additional_attributes['avatar_url_hash']).to eq(Digest::SHA256.hexdigest(new_url))
    end
  end

  context 'with regular avatarable' do
    let(:avatarable) { create(:agent_bot) }

    it 'downloads and attaches avatar' do
      stub_request(:get, valid_url)
        .to_return(
          status: 200,
          body: File.read(Rails.root.join('spec/assets/avatar.png')),
          headers: { 'Content-Type' => 'image/png' }
        )

      described_class.perform_now(avatarable, valid_url)
      expect(avatarable.avatar).to be_attached
    end
  end

  # ref: https://github.com/chatwoot/chatwoot/issues/10449
  it 'does not raise error when downloaded file has no filename (invalid content)' do
    contact = create(:contact)
    invalid_file = Tempfile.new('avatar-without-name')

    allow(SafeFetch).to receive(:fetch)
      .with(
        valid_url,
        max_bytes: Avatar::AvatarFromUrlJob::MAX_DOWNLOAD_SIZE,
        allowed_content_type_prefixes: [],
        allowed_content_types: Avatar::AvatarFromUrlJob::ALLOWED_CONTENT_TYPES
      ).and_yield(
        SafeFetch::Result.new(
          tempfile: invalid_file,
          filename: nil,
          content_type: 'image/png'
        )
      )

    expect { described_class.perform_now(contact, valid_url) }.not_to raise_error
    expect(contact.reload.avatar).not_to be_attached
  ensure
    invalid_file.close!
  end

  it 'skips sync attribute updates when URL is nil' do
    contact = create(:contact)

    expect { described_class.perform_now(contact, nil) }.not_to raise_error

    contact.reload
    expect(contact.additional_attributes['last_avatar_sync_at']).to be_nil
    expect(contact.additional_attributes['avatar_url_hash']).to be_nil
  end
end
