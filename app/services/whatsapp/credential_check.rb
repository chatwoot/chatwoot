# What a credential check answers when it could not reach a verdict.
#
# `validate_provider_config?` has two honest answers, the credential works or the provider refused it,
# and a boolean can only say those two. The third outcome is that nothing came back that says either:
# the socket timed out, the connection was refused, the provider answered that it could not answer
# right now, or answered something this side cannot read. Returned as `false`, that becomes "Invalid
# Credentials" to an operator whose credentials may be perfect; left to escape, it becomes a 500 that
# says the application broke (fazer-ai/chatwoot#598). So it is raised as its own class, and the one
# caller, `Channel::Whatsapp#validate_provider_config`, turns it into a validation error of its own.
#
# The rescue here is wide on purpose and narrow in scope, the same arrangement as
# Whatsapp::TransportFailure: anything StandardError can be at the HTTP call is a transport failure by
# construction, and an enumerated list would be a promise to have thought of every way a socket can
# fail. What keeps it honest is that nothing but the call sits under the rescue: the caller builds the URL,
# the headers and the body into locals first, and hands over a block holding only the HTTParty call. A
# defect of our own, a NoMethodError while building the request, between the requests or while reading an
# answer, is not a check that failed to conclude, and must not reach the operator as one: it escapes as
# itself.
#
# A block holding the call, rather than a helper that takes the verb and dispatches it, because the call
# has to stay where the ceiling fences can read it. `graph_request_options_spec`, the per-provider
# `*_request_options_spec` files and `spec/lib/request_ceilings_spec` each read the verb call on HTTParty and
# check the ceiling inside it; a `public_send` hid the four checks from all of them, and the ceilings those
# fences exist to guarantee were no longer being read.
module Whatsapp::CredentialCheck
  class Unavailable < StandardError; end

  private

  def credential_check_request
    yield
  rescue StandardError => e
    # The class only. A message can carry the request URL, and Z-API puts the token in the path.
    raise Unavailable, e.class.name
  end

  # A 5xx is the provider, or whatever stands in front of it, saying it cannot answer right now. A 429
  # is a ceiling on how often this account may ask. Neither is a statement about the credential, and a
  # refusal is the one reading that would send the operator to replace a token that works.
  def ensure_credential_verdict!(response)
    return unless response.code == 429 || response.code >= 500

    raise Unavailable, "HTTP #{response.code}"
  end

  # For a body the verdict depends on. HTTParty parses lazily and by the Content-Type it was given, so
  # bad JSON is not the only way to fail here: a gateway answering broken XML raises MultiXML::ParseError.
  # Only the parse sits under the rescue, so it is wide for the same reason as the request's. When the
  # answer is already known, as with a refusal whose body only feeds a log line, an unreadable body must
  # not change it: rescue Unavailable around this call.
  def credential_check_body(response)
    response.parsed_response
  rescue StandardError => e
    raise Unavailable, "unreadable body: #{e.class.name}"
  end
end
