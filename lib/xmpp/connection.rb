require 'blather/client/dsl'

class Xmpp::Connection
  include Blather::DSL

  delegate :connected?, to: :client

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def initialize(channel)
    @channel = channel.freeze
    setup channel.jid, channel.password

    client.clear_handlers :error
    handle :error do |e|
      Blather.logger.error "Channel #{channel.id} error: #{e}"

      channel.authorization_error! if e.is_a?(Blather::SASLError)
    end

    handle :disconnected do
      Blather.logger.info "Channel #{channel.id} disconnected"
      next true if @shutdown

      Blather.logger.info "Channel #{channel.id} reconnect in 5 seconds..."
      EM.add_timer(5) { run unless @shutdown }
      true
    end

    when_ready do
      Blather.logger.info "Channel #{channel.id} ready"

      self << Blather::Stanza::Iq.new(:set).tap do |iq|
        iq << Niceogiri::XML::Node.new(:enable, iq.document, 'urn:xmpp:carbons:2')
      end

      sync_mam(channel.last_mam_id)
    end

    message :error? do |m|
      message = Xmpp::ProcessMessageService::Outgoing.new(@channel, m).find_message
      err = Blather::StanzaError.import(m)
      message.status = :failed
      message.additional_attributes[:error] = err.name
      message.additional_attributes[:error_text] = err.text if err.text
      message.save!
    end

    message './ns:result', ns: 'urn:xmpp:mam:2' do |_, result|
      fwd = result.xpath('./ns:forwarded', ns: 'urn:xmpp:forward:0').first
      delay = fwd.xpath('./ns:delay', ns: 'urn:xmpp:delay').first&.[]('stamp')
      handle_forwarded_message(
        fwd.xpath('./ns:message', ns: 'jabber:client'),
        with: ->(m) { m.from.stripped.to_s == @channel.jid ? Xmpp::ProcessMessageService::Outgoing : Xmpp::ProcessMessageService },
        delay: delay,
        mam_id: result.first['id']&.to_s
      )
    end

    message './carbon:received/fwd:forwarded/*[1]', carbon: 'urn:xmpp:carbons:2', fwd: 'urn:xmpp:forward:0' do |_, fwd|
      handle_forwarded_message(fwd)
    end

    message './carbon:sent/fwd:forwarded/*[1]', carbon: 'urn:xmpp:carbons:2', fwd: 'urn:xmpp:forward:0' do |_, fwd|
      handle_forwarded_message(fwd, with: Xmpp::ProcessMessageService::Outgoing)
    end

    message './ns:received', ns: 'urn:xmpp:receipts' do |m, received|
      Xmpp::ProcessMessageService::Outgoing.new(@channel, m).find_message(received.first['id'])&.update!(status: :delivered)
    end

    message './ns:displayed', ns: 'urn:xmpp:chat-markers:0' do |m, displayed|
      Xmpp::ProcessMessageService::Outgoing.new(@channel, m).find_message(displayed.first['id'])&.update!(status: :read)
    end

    message :body do |m|
      service = Xmpp::ProcessMessageService.new(@channel, m)
      service.record_last_mam_id
      service.perform

      if m.id && m.xpath('./ns:request', ns: 'urn:xmpp:receipts')
        self << Blather::Stanza::Message.new.tap do |receipt|
          receipt << Niceogiri::XML::Node.new(:received, m.document, 'urn:xmpp:receipts').tap do |received|
            received['id'] = m.id
          end
        end
      end
    end
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def rsm(document, after_id)
    Niceogiri::XML::Node.new(:set, document, 'http://jabber.org/protocol/rsm').tap do |rsm|
      rsm << Niceogiri::XML::Node.new(:max, document, 'http://jabber.org/protocol/rsm').tap { |max| max.content = (EM.threadpool_size * 5).to_s }
      rsm << Niceogiri::XML::Node.new(:after, document, 'http://jabber.org/protocol/rsm').tap { |max| max.content = after_id } if after_id
    end
  end

  def sync_mam(last_id)
    start_mam = Blather::Stanza::Iq.new(:set).tap do |iq|
      iq << Niceogiri::XML::Node.new(:query, iq.document, 'urn:xmpp:mam:2').tap { |query| query << rsm(iq.document, last_id) }
    end

    client.write_with_handler(start_mam) do |reply|
      next if reply.error?

      fin = reply.xpath('./ns:fin', ns: 'urn:xmpp:mam:2')&.first
      next unless fin

      handle_rsm_reply_when_idle(fin)
    end
  end

  def handle_rsm_reply_when_idle(fin)
    unless EM.defers_finished?
      EM.add_timer(0.1) { handle_rsm_reply_when_idle(fin) }
      return
    end

    last = fin.xpath('./ns:set/ns:last', ns: 'http://jabber.org/protocol/rsm').first&.content
    Xmpp::ProcessMessageService.new(@channel, nil, mam_id: last).record_last_mam_id if last
    return if fin['complete'].to_s == 'true'

    sync_mam(last)
  end

  def handle_forwarded_message(fwd, with: Xmpp::ProcessMessageService, **kwargs)
    fwd = fwd.first if fwd.is_a?(Nokogiri::XML::NodeSet)
    return unless fwd

    m = Blather::XMPPNode.import(fwd)
    return unless m.is_a?(Blather::Stanza::Message) && m.body.present?

    with = with.call(m) if with.is_a?(Proc)

    with.new(@channel, m, **kwargs).perform
  end

  def shutdown
    @shutdown = true
    super
  end
end
