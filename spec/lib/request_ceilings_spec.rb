require 'rails_helper'

# The one-off integrations of #589: four third parties that share no client and no
# semantics, so each carries its own number. Grouped here because what they have in
# common is the absence, not the value.
#
# Each example goes through the real call and reads the options that went out. Counting
# the constant in the source proves the text is there, not that it resolves, and both
# things this sweep has broken so far were resolution and not text.
# rubocop:disable RSpec/DescribeClass -- there is no class here on purpose: the subject is
# four unrelated integrations and the numbers they do not share.
RSpec.describe 'the ceilings of the one-off integrations' do
  # hCaptcha sits in front of signup and login, so the person is looking at a form that
  # has not answered. Five seconds is already generous for checking a token.
  it 'keeps the captcha check short, because a person is waiting on a form' do
    options = nil
    allow(HTTParty).to receive(:post) do |_url, **kwargs|
      options = kwargs
      instance_double(HTTParty::Response, success?: true, parsed_response: { 'success' => true })
    end
    allow(GlobalConfigService).to receive(:load).with('HCAPTCHA_SERVER_KEY', '').and_return('a-key')

    ChatwootCaptcha.new('a-response').valid?

    expect(options).to include(timeout: 5, max_retries: 0)
  end

  # The opposite end of the same sweep. On the other side of this one an assistant is
  # composing an answer, so the thinking time before the first byte is the point of the
  # call and not a symptom: a short ceiling here would not save a worker, it would turn
  # every slow answer into no answer.
  it 'gives the assistant room to think, unlike every other ceiling here' do
    expect(Integrations::Captain::ProcessorService::CAPTAIN_REQUEST_OPTIONS)
      .to eq(timeout: 120, max_retries: 0)
    expect(Integrations::Captain::ProcessorService::CAPTAIN_REQUEST_OPTIONS[:timeout])
      .to be > ChatwootCaptcha::HCAPTCHA_REQUEST_OPTIONS[:timeout]
  end

  # An agent clicked a button and is waiting on the room to exist.
  it 'keeps the video room calls short' do
    options = nil
    allow(HTTParty).to receive(:get) do |_url, **kwargs|
      options = kwargs
      instance_double(HTTParty::Response, success?: true, parsed_response: {}, code: 200)
    end

    Dyte.new('acc', 'app', 'token').send(:get, 'presets')

    expect(options).to include(timeout: 10, max_retries: 0)
  end

  # Both token calls sit inside a `rescue StandardError` that answers with
  # `fallback_access_token`, which rereads the row and hands back the token it already
  # had. So a ceiling here does not surface a failure, it reaches a swallow faster: what
  # it buys is the worker, not the diagnosis. Exercised through the real call for the
  # usual reason, that a constant which does not resolve raises `NameError`, which is a
  # `StandardError`, which this very `rescue` would eat.
  it 'bounds the Linear token refresh, whose failure is swallowed' do
    hook = create(:integrations_hook, app_id: 'linear', access_token: 'old-token',
                                      settings: { refresh_token: 'r', expires_on: 1.hour.ago.to_s })
    options = nil
    allow(HTTParty).to receive(:post) do |_url, **kwargs|
      options = kwargs
      instance_double(HTTParty::Response, success?: false)
    end

    expect(Integrations::Linear::AccessTokenService.new(hook: hook).access_token).to eq('old-token')
    expect(options).to include(timeout: 15, max_retries: 0)
  end

  it 'bounds the GraphQL endpoint every issue action goes through' do
    options = nil
    allow(HTTParty).to receive(:post) do |_url, **kwargs|
      options = kwargs
      instance_double(HTTParty::Response, success?: true, parsed_response: { 'data' => { 'teams' => {} } })
    end

    Linear.new('a-token').teams

    expect(options).to include(timeout: 15, max_retries: 0)
  end

  # Nobody is waiting on this one: a job fetches the received email after the webhook was
  # already answered. What the ceiling buys is the worker, and failing lets Sidekiq retry
  # the job. The download carries the attachments, so it reads for longer than the lookup.
  it 'bounds both Resend calls of the inbound email job, the download longer than the lookup' do
    options = {}
    allow(HTTParty).to receive(:get) do |url, **kwargs|
      if url.start_with?('https://api.resend.com/')
        options[:lookup] = kwargs
        instance_double(HTTParty::Response, parsed_response: { 'raw' => { 'download_url' => 'https://inbound.resend.test/raw' } })
      else
        options[:download] = kwargs
        instance_double(HTTParty::Response, body: file_fixture('support_1.eml').read)
      end
    end

    with_modified_env RESEND_INBOUND_API_KEY: 're_full_access' do
      Webhooks::ResendInboundEmailJob.perform_now('em_123')
    end

    expect(options[:lookup]).to include(timeout: 15, max_retries: 0)
    expect(options[:download]).to include(timeout: 30, max_retries: 0)
  end

  # The fence the whole of #589 was for. Every HTTParty call in the tree carries both axes,
  # read by parsing the call rather than counting the word, because options arrive three
  # ways: written at the call, splatted from a constant, or built in a local first.
  #
  # `enterprise` is included only when it is there: the CE suite deletes that tree before
  # it runs, and a fence that reads a file the suite deleted fails for the wrong reason.
  it 'leaves no HTTParty call in the repo without a ceiling and without the retry closed' do
    require 'prism'

    roots = %w[app lib enterprise].select { |dir| Rails.root.join(dir).directory? }
    sources = Dir.glob(Rails.root.join("{#{roots.join(',')}}/**/*.rb"))

    constants = {}
    sources.each do |path|
      File.read(path).scan(/^\s*([A-Z][A-Z0-9_]*)\s*=\s*(\{.*?\})\.freeze/m) do |name, literal|
        constants[name] = { timeout: literal.include?('timeout'), retries: literal.include?('max_retries') }
      end
    end

    bare = sources.flat_map do |path|
      body = File.read(path)
      next [] unless body.include?('HTTParty')

      calls = []
      parsed = Prism.parse(body).value
      defs = []
      collect = lambda do |node|
        defs << node if node.is_a?(Prism::DefNode)
        node.compact_child_nodes.each { |child| collect.call(child) }
      end
      collect.call(parsed)

      stack = [parsed]
      until stack.empty?
        node = stack.pop
        stack.concat(node.compact_child_nodes)
        next unless node.is_a?(Prism::CallNode)
        next unless node.receiver.is_a?(Prism::ConstantReadNode) && node.receiver.name == :HTTParty

        text = (node.arguments&.arguments || []).map { |arg| body.byteslice(arg.location.start_offset, arg.location.length) }.join(', ')
        timeout = text.include?('timeout')
        retries = text.include?('max_retries')
        text.scan(/\*\*(?:[A-Z][A-Za-z0-9_]*::)*([A-Z][A-Z0-9_]*)/).flatten.each do |name|
          next unless constants[name]

          timeout ||= constants[name][:timeout]
          retries ||= constants[name][:retries]
        end

        # A call that splats a local is judged by the method that built that local. Looser
        # than the rest on purpose, and the looseness is bounded: it only applies where the
        # options were assembled a few lines above, which is what the uazapi client does
        # because it adds keys conditionally.
        if text.match?(/\*\*[a-z_]/)
          owner = defs.select { |d| d.location.start_offset <= node.location.start_offset && d.location.end_offset >= node.location.end_offset }
                      .min_by { |d| d.location.length }
          if owner
            enclosing = body.byteslice(owner.location.start_offset, owner.location.length)
            timeout ||= enclosing.include?('timeout')
            retries ||= enclosing.include?('max_retries')
          end
        end

        calls << "#{Pathname.new(path).relative_path_from(Rails.root)}:#{node.location.start_line}" unless timeout && retries
      end
      calls
    end

    expect(sources).not_to be_empty
    expect(bare).to be_empty
  end
end
# rubocop:enable RSpec/DescribeClass
