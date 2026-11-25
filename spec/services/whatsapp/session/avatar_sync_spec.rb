require 'rails_helper'

# The module had no spec of its own before #534, which mattered once its two writers moved onto
# the shared primitive: they were being changed without anything watching.
RSpec.describe Whatsapp::Session::AvatarSync do
  let(:contact) do
    create(:contact, additional_attributes: {
             'city' => 'Uberlandia',
             'last_avatar_sync_at' => 1.minute.ago.iso8601,
             'avatar_url_hash' => Digest::SHA256.hexdigest('https://example.com/old.png')
           })
  end

  # A fence over the avatar markers, and only over them. It catches a validation-skipping write
  # to this column, which is how the markers have to be persisted, since the avatar file checks
  # would refuse them. That is where this bug was written and where it would be rewritten.
  #
  # It is deliberately not a fence over every writer of the column. A dozen others use `update!`
  # or `save!`, most of them adjacent read-then-write with nothing slow in between, and what makes
  # this defect a defect is the order rather than the call: read, network, write. Grep cannot see
  # order, so a fence wide enough to cover them would be mostly false positives. The writers that
  # do span a network call are named in #542 and need a scenario each, not a pattern.
  it 'is the only place that skips validations to write this column' do
    roots = %w[app enterprise lib].select { |dir| Rails.root.join(dir).directory? }
    writers = Dir.glob(Rails.root.join("{#{roots.join(',')}}/**/*.rb")).select do |path|
      File.read(path).match?(/update_columns?\(\s*additional_attributes/)
    end

    expect(writers.map { |path| Pathname.new(path).relative_path_from(Rails.root).to_s })
      .to contain_exactly('app/models/concerns/avatarable.rb')
  end

  # The fence that actually protects the markers, and the one that survives the objection to the
  # other. It watches the key names rather than the call, so it does not care whether a future
  # writer reaches the column with `update!`, `save!` or an index assignment: naming a marker at
  # all is what trips it. Both files that may name one write through the primitive.
  it 'is named in exactly the two places that own it' do
    roots = %w[app enterprise lib].select { |dir| Rails.root.join(dir).directory? }
    owners = Dir.glob(Rails.root.join("{#{roots.join(',')}}/**/*.rb")).select do |path|
      body = File.read(path)
      (described_class::MARKERS + [described_class::REMOVED_AT]).any? { |marker| body.include?(marker) }
    end

    expect(owners.map { |path| Pathname.new(path).relative_path_from(Rails.root).to_s })
      .to contain_exactly('app/services/whatsapp/session/avatar_sync.rb',
                          'app/jobs/avatar/avatar_from_url_job.rb')
  end

  describe '.reset' do
    it 'clears both markers and leaves everything else alone' do
      described_class.reset(contact)

      expect(contact.reload.additional_attributes).to eq('city' => 'Uberlandia')
    end

    it 'ignores a blank contact' do
      expect { described_class.reset(nil) }.not_to raise_error
    end

    # The markers are what a stale picture has to clear before it can be refetched, so a caller
    # that read the hash before a round trip must not put them back by writing its own copy.
    it 'does not restore a marker another writer cleared first' do
      stale = Contact.find(contact.id)
      contact.update_avatar_sync_markers!(remove: described_class::MARKERS)

      described_class.reset(stale)

      expect(contact.reload.additional_attributes).not_to include('avatar_url_hash')
    end
  end

  describe '.remove' do
    it 'drops the picture and records when' do
      contact.avatar.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png',
                            content_type: 'image/png')

      described_class.remove(contact)

      contact.reload
      expect(contact.avatar).not_to be_attached
      expect(contact.additional_attributes).to include(described_class::REMOVED_AT)
      expect(contact.additional_attributes).to include('city' => 'Uberlandia')
      expect(contact.additional_attributes.keys).not_to include(*described_class::MARKERS)
    end

    it 'records the removal even when nothing was attached' do
      described_class.remove(contact)

      expect(contact.reload.additional_attributes).to include(described_class::REMOVED_AT)
    end

    # `remove` purges the blob first, which is a round trip to storage. Anything written to the
    # column while that runs has to survive, or the removal marker lands on a stale hash and
    # takes the other writer's key with it.
    it 'keeps a key written while the blob was being purged' do
      contact.avatar.attach(io: Rails.root.join('spec/assets/avatar.png').open, filename: 'avatar.png',
                            content_type: 'image/png')
      allow(contact.avatar).to receive(:purge) do
        other = Contact.find(contact.id)
        # Deliberately not the shared primitive: this stands in for a writer that does not use
        # it, which is the whole hazard under test.
        other.update_columns(additional_attributes: (other.additional_attributes || {}).merge('country' => 'BR')) # rubocop:disable Rails/SkipsModelValidations
      end

      described_class.remove(contact)

      expect(contact.reload.additional_attributes).to include('country' => 'BR', described_class::REMOVED_AT => anything)
    end
  end

  describe '.refetch' do
    it 'clears the markers and queues the download with the moment the url was resolved' do
      expect { described_class.refetch(contact, 'https://example.com/new.png') }
        .to have_enqueued_job(Avatar::AvatarFromUrlJob)
        .with(contact, 'https://example.com/new.png', resolved_at: anything)

      expect(contact.reload.additional_attributes.keys).not_to include(*described_class::MARKERS)
    end

    it 'does nothing without a url' do
      expect { described_class.refetch(contact, nil) }.not_to have_enqueued_job(Avatar::AvatarFromUrlJob)
    end
  end
end
