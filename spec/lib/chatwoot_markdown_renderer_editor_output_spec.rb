require 'rails_helper'

# Byte-exact markdown the dashboard editor (@chatwoot/prosemirror-schema)
# emits for Enter / Shift+Enter combinations. An empty visual line is stored
# as a `\` hard-break line glued to the next paragraph, and a dashes/equals
# line below it is escaped (`\--`, `\-`, `\==`) so cmark cannot read the pair
# as a setext heading. Every channel renderer must show no backslash, no
# accidental heading, and keep the composed lines.
describe ChatwootMarkdownRenderer do
  signature_tail = "\n\nThanks \\\nSivin | Chatwoot\n\n![](https://example.com/logo.png)"

  fixtures = {
    enter_above_signature: { markdown: "hey\n\n\\\n\\--#{signature_tail}", email_breaks: 2, whatsapp: "hey\n\n\n--\n\nThanks \nSivin | Chatwoot" },
    shift_enter_then_dashes_same_line: { markdown: "hey\\\n\\--", email_breaks: 1, whatsapp: "hey\n--" },
    multiple_breaks_above_signature: { markdown: "hey\n\n\\\n\\\n\\--#{signature_tail}", email_breaks: 3,
                                       whatsapp: "hey\n\n\n\n--\n\nThanks \nSivin | Chatwoot" },
    mixed_enter_and_breaks: { markdown: "mix\n\n\\\n\\\n\\--#{signature_tail}", email_breaks: 3,
                              whatsapp: "mix\n\n\n\n--\n\nThanks \nSivin | Chatwoot" },
    three_enters_four_breaks: { markdown: "sd\n\n\\\n\\\n\\\n\\\n\\\n\\\n\\--#{signature_tail}", email_breaks: 7,
                                whatsapp: "sd\n\n\n\n\n\n\n\n--\n\nThanks \nSivin | Chatwoot" },
    equals_underline_below_empty: { markdown: "a\n\n\\\n\\==", email_breaks: 1, whatsapp: "a\n\n\n==" },
    empty_line_between_text: { markdown: "a\n\n\\\nb", email_breaks: 1, whatsapp: "a\n\n\nb" },
    two_empty_lines_between_text: { markdown: "a\n\n\\\n\\\nb", email_breaks: 2, whatsapp: "a\n\n\n\nb" },
    mid_paragraph_double_break: { markdown: "a\\\n\\\nb", email_breaks: 2, whatsapp: "a\n\nb" },
    plain_hard_break: { markdown: "line one\\\nline two", email_breaks: 1, whatsapp: "line one\nline two" },
    legacy_space_padded_breaks: { markdown: "zz \n\n\\\n\\\n\\--#{signature_tail}", email_breaks: 3,
                                  whatsapp: "zz \n\n\n\n--\n\nThanks \nSivin | Chatwoot" },
    break_then_list_text: { markdown: "intro\n- item", email_breaks: 0, whatsapp: "intro\n- item" },
    break_then_thematic: { markdown: "intro\n***", email_breaks: 0, whatsapp: 'intro' },
    empty_before_pasted_list_text: { markdown: "a\n\n\n- pasted", email_breaks: 0, whatsapp: "a\n\n\n- pasted" },
    empty_before_list_node: { markdown: "a\n\n\n* item", email_breaks: 0, whatsapp: "a\n\n\n* item" },
    empty_before_image: { markdown: "a\n\n![](https://example.com/logo.png)", email_breaks: 0, whatsapp: 'a' },
    trailing_breaks_no_signature: { markdown: 'hello', email_breaks: 0, whatsapp: 'hello' },
    dash_after_break: { markdown: "a\\\n\\-", email_breaks: 1, whatsapp: "a\n-" },
    dash_below_empty: { markdown: "x\n\n\\\n\\-", email_breaks: 1, whatsapp: "x\n\n\n-" },
    dash_above_signature: { markdown: "e1\\\n\\-\n\n--#{signature_tail}", email_breaks: 2,
                            whatsapp: "e1\n-\n\n--\n\nThanks \nSivin | Chatwoot" },
    bare_marker_after_break: { markdown: "e2\\\n\\- \n\n--#{signature_tail}", email_breaks: 2,
                               whatsapp: "e2\n- \n\n--\n\nThanks \nSivin | Chatwoot" },
    bold_underline_after_break: { markdown: "a\\\n**--**", email_breaks: 1, whatsapp: "a\n*--*",
                                  email_delimiter: '<strong>--</strong></p>' },
    indented_underline_detached: { markdown: "b2\n\n  --", email_breaks: 0, whatsapp: "b2\n\n  --" }
  }

  html_channels = %w[Channel::Email Channel::WebWidget]
  text_channels = %w[Channel::Telegram Channel::Whatsapp Channel::Instagram Channel::Line Channel::Sms]
  hardbreak_modes = [true, false].freeze

  fixtures.each do |name, fixture|
    context "with #{name.to_s.tr('_', ' ')}" do
      it 'renders without backslash artifacts or accidental headings on every channel' do
        hardbreak_modes.each do |hardbreaks|
          html = described_class.new(fixture[:markdown]).render_message(hardbreaks: hardbreaks).to_s
          expect(html).not_to include('\\'), "render_message(hardbreaks: #{hardbreaks}) leaked a backslash: #{html.inspect}"
          expect(html).not_to match(/<h[12]/), "render_message(hardbreaks: #{hardbreaks}) produced a heading: #{html.inspect}"
        end

        (html_channels + text_channels).each do |channel|
          rendered = Messages::MarkdownRendererService.new(fixture[:markdown], channel).render
          expect(rendered).not_to include('\\'), "#{channel} leaked a backslash: #{rendered.inspect}"
          expect(rendered).not_to match(/<h[12]/), "#{channel} produced a heading: #{rendered.inspect}"
        end
      end

      it 'preserves the composed lines in the email html' do
        html = described_class.new(fixture[:markdown]).render_message(hardbreaks: true).to_s
        expect(html.scan('<br').size).to eq(fixture[:email_breaks])
        delimiter = fixture.fetch(:email_delimiter) { fixture[:markdown].include?('--') ? '--</p>' : nil }
        expect(html).to include(delimiter) if delimiter
      end

      it 'preserves the composed lines as plain newlines on text channels' do
        rendered = Messages::MarkdownRendererService.new(fixture[:markdown], 'Channel::Whatsapp').render
        expect(rendered.rstrip).to eq(fixture[:whatsapp])
      end
    end
  end

  context 'with the email helper used to build stored email html' do
    it 'renders the signature shape with the empty line and delimiter intact' do
      html = Class.new { include EmailHelper }.new.render_email_html("hey\n\n\\\n\\--#{signature_tail}")
      expect(html).to include("<p><br />\n--</p>")
      expect(html).not_to include('\\')
    end
  end
end
