class Integrations::MutodayFaqReply::Copy
  # D1 — the compliance disclosure. These two constants, and only these, are what make the
  # label unconditional. One of them is prepended in Ruby to every message this feature
  # creates; the model is never asked to label itself and could not do so if it tried,
  # because it only ever returns an id from a closed set.
  #
  # Which one is chosen by the recorded route, never by content (C12). On day one the
  # corpus is empty, so no model call happens at all; stamping "AI" on a static Ruby
  # constant would be a false statement in the opposite direction, and would let the
  # promotion gate "prove" 100% AI disclosure on a system containing no AI.
  #
  # Neither may contain Liquid delimiters ({{ }} {% %}) — Liquidable#process_liquid_in_content
  # runs on every :template message (app/models/concerns/liquidable.rb:6, 23) and rescues
  # Liquid::Error silently. Neither may contain Markdown — Messages::MarkdownRendererService
  # rewrites it for LINE (markdown_renderer_service.rb:9 → LineRenderer).
  AI_DISCLOSURE = '[ตอบอัตโนมัติด้วย AI]'.freeze
  AUTO_DISCLOSURE = '[ข้อความอัตโนมัติ]'.freeze

  # A route names how the reply was chosen and is recorded on the message. Every route the
  # model took part in starts with "model"; that prefix is the whole rule, and it is the
  # same test the promotion gate's SQL uses (route LIKE 'model%').
  MODEL_ROUTE_PREFIX = 'model'.freeze

  HANDOFF = 'เจ้าหน้าที่จะเข้ามาตอบต่อจากนี้ครับ ถ้ามีรายละเอียดเพิ่มเติม พิมพ์บอกไว้ได้เลย'.freeze

  ACKNOWLEDGEMENT = 'ได้รับข้อความแล้วครับ ขอบคุณที่ติดต่อ MU Today'.freeze

  ROUTED_TO_HUMAN = 'ได้รับเรื่องแล้วครับ เรื่องนี้ขอให้เจ้าหน้าที่เป็นผู้ตอบ กำลังส่งต่อให้ดูแลต่อ'.freeze

  # The corpus answer is the only input of unbounded length. apps.yml caps `a` at 1200
  # characters and the importer checks the same, so this mirrors that cap at the point the
  # string is assembled and keeps the message far below LINE's 5000-character limit — over
  # that limit the push is rejected and the row lands as status 'failed' while the customer
  # sees silence (Chatwoot itself only validates 150_000, message.rb:80).
  #
  # The answer is truncated rather than the finished body on purpose: cutting the assembled
  # string would take the handoff line off the end, and on a long answer it would take the
  # promise that a human is coming with it.
  MAX_ANSWER = 1_200

  # Liquid delimiters are stripped rather than escaped. The FAQ answer is admin-typed text;
  # an unintended {{contact.name}} render on a compliance-labelled message is worse than
  # losing a templating feature nobody asked for, and a malformed {% %} would be rescued
  # silently by Liquidable and shipped raw to the customer.
  LIQUID_DELIMITERS = /\{\{|\}\}|\{%|%\}/

  class << self
    # The model picked an approved answer. `route` is always a model_* route here.
    def matched(answer, route:)
      assemble(route, [sanitize(answer), HANDOFF])
    end

    # No approved answer applies: an empty corpus, a non-text message, a model that
    # returned no match, or any model failure. The customer is never left in silence.
    def unmatched(route:)
      assemble(route, [ACKNOWLEDGEMENT, HANDOFF])
    end

    # A deny-list topic. No model ran, and the conversation is labelled for an agent.
    def routed(route:)
      assemble(route, [ROUTED_TO_HUMAN])
    end

    def disclosure_for(route)
      route.to_s.start_with?(MODEL_ROUTE_PREFIX) ? AI_DISCLOSURE : AUTO_DISCLOSURE
    end

    private

    def assemble(route, paragraphs)
      [disclosure_for(route), *paragraphs].join("\n\n")
    end

    def sanitize(text)
      text.to_s.gsub(LIQUID_DELIMITERS, '').strip.truncate(MAX_ANSWER)
    end
  end
end
