require 'rails_helper'

describe Whatsapp::GraphRequestOptions do
  # Every file that talks to Meta's Graph API. A call added to any of them without the ceiling is the
  # whole failure this fence exists for: the alternative was a line in a review checklist, and a
  # checklist is read once.
  let(:guarded_sources) do
    %w[
      app/services/whatsapp/facebook_api_client.rb
      app/services/whatsapp/health_service.rb
      app/services/whatsapp/providers/whatsapp_cloud_service.rb
      app/services/whatsapp/business_management_token_validation_service.rb
      app/services/whatsapp/csat_template_service.rb
      app/services/whatsapp/incoming_message_whatsapp_cloud_service.rb
      app/services/whatsapp/business_profile_service.rb
      app/services/whatsapp/providers/whatsapp_cloud_contact_info_request_service.rb
    ]
  end

  # The WhatsApp services that speak to something other than the Graph API. They are listed rather
  # than skipped so that a file is never simply absent: absent is how the first sweep missed most of
  # the repo, and it is the state the check below refuses. Each of these is a family of its own with
  # its own ceiling to decide, which is fazer-ai/chatwoot#589.
  let(:other_families) do
    {
      # Its own API, not Meta's, and the one with two ceilings rather than one: 90s by default,
      # above the cut its own proxy applies, and 10s on the reads that give up before it does.
      # Fenced by spec/services/whatsapp/baileys_request_options_spec.rb, which also counts each
      # side, so this entry is a pointer and not an exemption.
      'app/services/whatsapp/providers/whatsapp_baileys_service.rb' => 'Baileys API, fenced by its own two-ceiling spec',
      'app/services/whatsapp/providers/whatsapp_zapi_service.rb' => 'Z-API, fenced by its own two-ceiling spec',
      'app/services/whatsapp/providers/whatsapp_360_dialog_service.rb' => '360dialog, fenced by its own spec',
      # uazapi, and already the most careful caller in the repo: its own TIMEOUT constant, a separate
      # open_timeout, and read and write timeouts set apart because HTTParty's `timeout` sets all
      # three. It is also the one file a scan for `HTTParty.<verb>(` cannot see, because it dispatches
      # the verb -- which is why this check looks for the string and not for the call shape.
      'app/services/whatsapp/session/backends/uazapi/client.rb' => 'uazapi session client, ceilings already set per axis',
      # Upstream's Enterprise code, which the fork neither modifies nor patches: its Graph calls
      # carry whatever options upstream gives them.
      'enterprise/app/services/enterprise/whatsapp/providers/whatsapp_cloud_service.rb' => 'upstream Enterprise, not ours to change',
      'enterprise/app/services/enterprise/whatsapp/providers/whatsapp_cloud_call_settings.rb' => 'upstream Enterprise, not ours to change'
    }
  end

  # Where a WhatsApp service lives. Both trees, because the enterprise one is not a copy of the other
  # and has Graph calls of its own.
  let(:whatsapp_service_trees) do
    %w[app/services/whatsapp enterprise/app/services/enterprise/whatsapp]
  end

  # Reads a call the way the parser would, not the way a line-oriented grep would: `HTTParty.get(`
  # opens a call that runs for several lines, and only the text up to its matching paren says
  # whether the options are in THIS call or in the next one further down the file.
  def graph_calls(source)
    calls = []
    source.to_enum(:scan, /HTTParty\.(?:get|post|put|patch|delete)\(/).each do
      start = Regexp.last_match.begin(0)
      depth = 0
      source[start..].each_char.with_index do |char, offset|
        depth += 1 if char == '('
        next unless char == ')'

        depth -= 1
        next unless depth.zero?

        calls << source[start, offset + 1]
        break
      end
    end
    calls
  end

  it 'reads a call to its own closing paren, not to the first one it meets' do
    # Every call in the guarded files happens to carry the options right after the URL, so a scanner
    # that stopped at the first `)` would still find them and this fence would pass for the wrong
    # reason. It would then report a false offender the day a call carries the options after an
    # argument that has parens of its own, which is what this arrangement is.
    source = <<~RUBY
      HTTParty.get(
        "\#{BASE_URI}/\#{@api_version}/x",
        query: { token: GlobalConfigService.load('A', '') },
        **GRAPH_REQUEST_OPTIONS
      )
    RUBY

    expect(graph_calls(source).first).to include('GRAPH_REQUEST_OPTIONS')
  end

  it 'caps the wait and the retry, because a ceiling alone still costs twice on a read' do
    expect(described_class::GRAPH_REQUEST_OPTIONS).to eq(timeout: 10, max_retries: 0)
  end

  it 'leaves no Graph call in the guarded files without the ceiling' do
    without_ceiling = guarded_sources.flat_map do |path|
      graph_calls(Rails.root.join(path).read)
        .reject { |call| call.include?('GRAPH_REQUEST_OPTIONS') }
        .map { |call| "#{path}: #{call.lines.first.strip} #{call.lines[1].to_s.strip}" }
    end

    expect(without_ceiling).to be_empty
  end

  it 'reads every call in the guarded files, so an empty result cannot pass as a clean one' do
    # The check above answers "nothing without a ceiling", and it answers that for zero calls too.
    # This one measures that the scan actually reached the calls it was supposed to inspect.
    expected = {
      # Sixteen since 4.18.0: the guided manual setup reads the WABA's numbers, templates, business
      # profile, permissions and subscriptions through this client, and each read got the ceiling
      # on the way in.
      'app/services/whatsapp/facebook_api_client.rb' => 17,
      'app/services/whatsapp/health_service.rb' => 1,
      # Six rather than ten: the five sends now go through `post_outgoing`, which is the single
      # HTTParty call on the outgoing path and carries the ceiling for all of them. That
      # indirection is what fazer-ai/chatwoot#605 needed, and collapsing five inspected calls into
      # one is the count moving for a reason, not a call losing its ceiling.
      'app/services/whatsapp/providers/whatsapp_cloud_service.rb' => 6,
      'app/services/whatsapp/business_management_token_validation_service.rb' => 2,
      'app/services/whatsapp/csat_template_service.rb' => 3,
      'app/services/whatsapp/incoming_message_whatsapp_cloud_service.rb' => 1,
      'app/services/whatsapp/business_profile_service.rb' => 1,
      'app/services/whatsapp/providers/whatsapp_cloud_contact_info_request_service.rb' => 1
    }
    counts = guarded_sources.index_with { |path| graph_calls(Rails.root.join(path).read).size }

    expect(counts).to eq(expected)
  end

  # The list above is written by hand, and a hand-written list has one failure mode: a new file that
  # nobody adds to it. That is not hypothetical -- this fence guarded two files while twenty more
  # Graph calls sat outside it, and the only thing that found them was somebody counting by hand.
  # So a WhatsApp service that reaches the network is either guarded or declared to be another
  # family, and being absent from both is what fails.
  it 'leaves no WhatsApp service unaccounted for, guarded or declared another family' do
    sources = whatsapp_service_trees.flat_map { |tree| Dir.glob(Rails.root.join(tree, '**/*.rb')) }
    reaching_the_network = sources
                           .select { |path| File.read(path).include?('HTTParty.') }
                           .map { |path| Pathname.new(path).relative_path_from(Rails.root).to_s }

    expect(reaching_the_network).not_to be_empty
    expect(reaching_the_network - guarded_sources - other_families.keys).to be_empty
  end

  it 'declares a reason for every family it does not guard' do
    expect(other_families.values).to all(be_present)
  end
end
