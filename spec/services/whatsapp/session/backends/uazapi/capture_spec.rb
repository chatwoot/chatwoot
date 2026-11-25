require 'rails_helper'

# The uazapi fixtures are one capture: a single instance, paired with a single number,
# talking to a single peer. Two specs read the paired number out of it, one from a webhook
# body and one from the REST status, and for a while those two disagreed, because
# redacting the capture by hand had put the peer's number in the instance's `owner`. Both
# specs passed anyway: each only restated the file it read, so the wrong number was the
# expectation as much as it was the fixture.
#
# Hence the property is asserted across the whole capture rather than per file. Nothing
# here exercises the build; it guards the evidence every other uazapi spec is written
# against, and it is the mistake that redacting a capture by hand makes every time.
# Not a class: what it describes is the fixture set itself.
RSpec.describe 'The uazapi capture' do # rubocop:disable RSpec/DescribeClass
  # The instance the capture was taken on, and the number on the other end of every chat
  # in it. Both appear all over the fixtures: what matters is which fields carry which.
  let(:instance_number) { '5511999990001' }
  let(:peer_number) { '553499990002' }

  let(:root) { Rails.root.join('spec/fixtures/whatsapp/session/uazapi') }
  let(:bodies) { Dir[root.join('**/*.json')].to_h { |path| [Pathname(path).relative_path_from(root).to_s, JSON.parse(File.read(path))] } }

  # Every field that means "the number this instance is paired with", wherever the
  # provider puts it: at the top of a webhook body, inside the instance record of a REST
  # status, and in the JID of that status. `status` is a string on a webhook body and an
  # object on a REST one, and `instance` is a string on some of the group bodies, so each
  # is read only where it is one.
  def owners(body)
    return [] unless body.is_a?(Hash)

    nested = ->(key, field) { body[key].is_a?(Hash) ? body[key][field] : nil }

    [body['owner'], nested.call('instance', 'owner'), nested.call('status', 'jid')&.split(/[:@]/)&.first].compact_blank
  end

  it 'names the same instance everywhere it names one' do
    named = bodies.transform_values { |body| owners(body) }.reject { |_name, list| list.empty? }

    expect(named.reject { |_name, list| list.all?(instance_number) }).to be_empty
  end

  it 'never files the peer under a field that names the instance' do
    expect(bodies.select { |_name, body| owners(body).include?(peer_number) }).to be_empty
  end

  # The redaction is only worth trusting if it left both halves in place: a capture where
  # every number came out the same would satisfy the two expectations above and prove
  # nothing about a build that has to tell the two apart.
  it 'still has both numbers in it' do
    serialized = bodies.values.map(&:to_json)

    expect(serialized).to include(a_string_including(instance_number)).and include(a_string_including(peer_number))
  end
end
