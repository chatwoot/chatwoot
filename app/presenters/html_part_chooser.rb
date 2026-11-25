# Which `text/html` part of a message carries what the sender wrote.
#
# Its own class because it is a policy with a cost, not a step. `Mail::Message#html_part`
# answers with the first `text/html` it meets in a depth-first walk, which is right almost
# always and silently wrong on a shape iOS Mail produces: a `multipart/alternative` whose
# one child is a `multipart/mixed`, holding a stub of a hundred-odd bytes, then the
# attachment, then the part the customer actually wrote. The stub renders to nothing, so
# the message reaches the agent as an empty bubble under a subject -- no error, no
# attachment missing, just no words.
class HtmlPartChooser
  def self.for(mail) = new(mail).perform

  def initialize(mail)
    @mail = mail
  end

  # The gem's answer stands unless there is a choice to make and its answer says nothing,
  # so every message whose first part is the real one keeps the part it has today. That
  # restraint is the point: taking the largest outright would prefer a quoted forward over
  # the short reply written above it, which is a worse failure than the one being fixed and
  # a far more common shape.
  #
  # The two cheap tests come before the expensive one on purpose. This sits on every inbound
  # email and answering it costs a full parse, so the parse is reached only by a message
  # that actually carries rival parts.
  def perform
    chosen = @mail.html_part
    rivals = body_parts.select { |part| part.mime_type == 'text/html' }
    return chosen if chosen.nil? || rivals.length < 2 || rendered(chosen).present?

    rivals.max_by { |part| rendered(part).length } || chosen
  end

  private

  # The parts of the message itself, which is not every part it carries. An attached
  # document has parts of its own, and a `text/html` inside one reads, to a flat walk,
  # exactly like a candidate. It is not one, and preferring it because it is longer than the
  # reply above it is precisely the failure this class exists to avoid.
  #
  # `attachment?` alone does not answer where to stop: it is a question about a file, a
  # disposition plus a name, and the container holding an attached document has no name. A
  # `multipart/related` carrying `Content-Disposition: attachment` answers false while every
  # leaf under it is attached content. Reading the disposition as well is what makes the
  # walk stop at the top of that subtree rather than one level inside it.
  def body_parts(part = @mail, found = [])
    body_children(part).each do |child|
      next if attached?(child)

      found << child
      body_parts(child, found) if child.multipart?
    end
    found
  end

  # Which children of a container are the message. Under `multipart/alternative` and
  # `multipart/mixed` all of them are. Under `multipart/related` only one is: the rest are
  # resources the body points at by `Content-ID`, an image almost always, but a `text/html`
  # fragment reads to a flat walk exactly like a candidate and is not one. RFC 2387 names
  # that one in `start`, and means the first child when it says nothing.
  #
  # The gem gets this right by accident -- its answer is the first `text/html` in order, and
  # the root comes first -- so looking past an empty body without this would be a new way to
  # be wrong, not a fix.
  def body_children(part)
    children = part.parts
    return children unless part.mime_type == 'multipart/related'

    [root_of(part, children)].compact
  end

  def root_of(part, children)
    named = part.content_type_parameters.to_h['start'].to_s
    return children.first if named.blank?

    children.find { |child| cid(child) == unbracket(named) } || children.first
  end

  def cid(part)
    unbracket(part.content_id.to_s)
  rescue StandardError
    ''
  end

  def unbracket(value)
    value.strip.delete_prefix('<').delete_suffix('>')
  end

  def attached?(part)
    part.attachment? || part.content_disposition.to_s.strip.downcase.start_with?('attachment')
  rescue StandardError
    false
  end

  # What a part is worth to a reader, which is the same question the caller asks of it a
  # moment later. A part that is only markup answers with nothing.
  #
  # `decoded` and not `body.decoded`, because they are different questions and only the
  # first is the one being asked. `body.decoded` undoes the transfer encoding and stops,
  # handing back bytes tagged binary; `decoded` goes on to transcode the charset the part
  # declares, which is what the presenter renders a moment later. On any charset a byte
  # wide the two agree, so the gap only opens on UTF-16 and its family -- where the raw
  # bytes parse to nothing at all, a part that says something scores zero, and a one-word
  # rival wins on length.
  def rendered(part)
    ::HtmlParser.parse_reply(part.decoded.to_s).to_s
  rescue StandardError
    ''
  end
end
