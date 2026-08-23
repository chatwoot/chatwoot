require 'rails_helper'

RSpec.describe Messages::MarkdownRendererService, type: :service do
  describe '#render' do
    context 'when content is blank' do
      let(:channel) { instance_double(Channel::Whatsapp, renderer: :render_whatsapp) }

      it 'returns the content as-is for nil' do
        result = described_class.new(nil, channel).render
        expect(result).to be_nil
      end

      it 'returns the content as-is for empty string' do
        result = described_class.new('', channel).render
        expect(result).to eq('')
      end
    end

    context 'when channel is Channel::Whatsapp' do
      let(:channel) { instance_double(Channel::Whatsapp, renderer: :render_whatsapp) }

      it 'converts bold from double to single asterisk' do
        content = '**bold text**'
        result = described_class.new(content, channel).render
        expect(result.strip).to eq('*bold text*')
      end

      it 'keeps italic with underscore' do
        content = '_italic text_'
        result = described_class.new(content, channel).render
        expect(result.strip).to eq('_italic text_')
      end

      it 'keeps code with backticks' do
        content = '`code`'
        result = described_class.new(content, channel).render
        expect(result.strip).to eq('`code`')
      end

      it 'converts links to URLs only' do
        content = '[link text](https://example.com)'
        result = described_class.new(content, channel).render
        expect(result.strip).to eq('https://example.com')
      end

      it 'handles combined formatting' do
        content = '**bold** _italic_ `code` [link](https://example.com)'
        result = described_class.new(content, channel).render
        expect(result.strip).to eq('*bold* _italic_ `code` https://example.com')
      end

      it 'handles nested formatting' do
        content = '**bold _italic_**'
        result = described_class.new(content, channel).render
        expect(result.strip).to eq('*bold _italic_*')
      end

      it 'preserves unordered list with dash markers' do
        content = "- item 1\n- item 2\n- item 3"
        result = described_class.new(content, channel).render
        expect(result).to include('- item 1')
        expect(result).to include('- item 2')
        expect(result).to include('- item 3')
      end

      it 'converts asterisk unordered lists to dash markers' do
        content = "* item 1\n* item 2\n* item 3"
        result = described_class.new(content, channel).render
        expect(result).to include('- item 1')
        expect(result).to include('- item 2')
        expect(result).to include('- item 3')
      end

      it 'preserves ordered list markers with numbering' do
        content = "1. first step\n2. second step\n3. third step"
        result = described_class.new(content, channel).render
        expect(result).to include('1. first step')
        expect(result).to include('2. second step')
        expect(result).to include('3. third step')
      end

      it 'preserves newlines in plain text without list markers' do
        content = "Line 1\nLine 2\nLine 3"
        result = described_class.new(content, channel).render
        expect(result).to include("Line 1\nLine 2\nLine 3")
        expect(result).not_to include('Line 1 Line 2')
      end

      it 'preserves multiple consecutive newlines for spacing' do
        content = "Para 1\n\n\n\nPara 2"
        result = described_class.new(content, channel).render
        expect(result.scan("\n").count).to eq(4)
        expect(result).to include("Para 1\n\n\n\nPara 2")
      end

      it 'renders code blocks as plain text' do
        content = "```\ncode here\n```"
        result = described_class.new(content, channel).render
        expect(result.strip).to eq('code here')
      end

      it 'renders indented code blocks as plain text preserving exact content' do
        content = '    indented code line'
        result = described_class.new(content, channel).render
        expect(result).to eq('indented code line')
      end

      it 'handles code blocks with emojis and special characters without stack overflow' do
        content = "    first line\n    🌐 second line\n"
        result = described_class.new(content, channel).render
        expect(result).to eq("first line\n🌐 second line")
      end
    end

    context 'when channel is Channel::Instagram' do
      let(:channel) { instance_double(Channel::Instagram, renderer: :render_instagram) }

      it 'converts bold from double to single asterisk' do
        content = '**bold text**'
        result = described_class.new(content, channel).render
        expect(result.strip).to eq('*bold text*')
      end

      it 'keeps italic with underscore' do
        content = '_italic text_'
        result = described_class.new(content, channel).render
        expect(result.strip).to eq('_italic text_')
      end

      it 'strips code backticks' do
        content = '`code`'
        result = described_class.new(content, channel).render
        expect(result.strip).to eq('code')
      end

      it 'converts links to URLs only' do
        content = '[link text](https://example.com)'
        result = described_class.new(content, channel).render
        expect(result.strip).to eq('https://example.com')
      end

      it 'preserves bullet list markers' do
        content = "- first item\n- second item"
        result = described_class.new(content, channel).render
        expect(result).to include('- first item')
        expect(result).to include('- second item')
      end

      it 'preserves ordered list markers with numbering' do
        content = "1. first step\n2. second step"
        result = described_class.new(content, channel).render
        expect(result).to include('1. first step')
        expect(result).to include('2. second step')
      end

      it 'preserves newlines in plain text without list markers' do
        content = "Line 1\nLine 2\nLine 3"
        result = described_class.new(content, channel).render
        expect(result).to include("Line 1\nLine 2\nLine 3")
        expect(result).not_to include('Line 1 Line 2')
      end

      it 'preserves multiple consecutive newlines for spacing' do
        content = "Para 1\n\n\n\nPara 2"
        result = described_class.new(content, channel).render
        expect(result.scan("\n").count).to eq(4)
        expect(result).to include("Para 1\n\n\n\nPara 2")
      end

      it 'renders code blocks as plain text' do
        content = "```\ncode here\n```"
        result = described_class.new(content, channel).render
        expect(result.strip).to eq('code here')
      end

      it 'renders indented code blocks as plain text preserving exact content' do
        content = '    indented code line'
        result = described_class.new(content, channel).render
        expect(result).to eq('indented code line')
      end

      it 'handles code blocks with emojis and special characters without stack overflow' do
        content = "    first line\n    🌐 second line\n"
        result = described_class.new(content, channel).render
        expect(result).to eq("first line\n🌐 second line")
      end
    end

    context 'when channel is Channel::Line' do
      let(:channel) { instance_double(Channel::Line, renderer: :render_line) }

      it 'adds spaces around bold markers' do
        content = '**bold**'
        result = described_class.new(content, channel).render
        expect(result).to include(' *bold* ')
      end

      it 'adds spaces around italic markers' do
        content = '_italic_'
        result = described_class.new(content, channel).render
        expect(result).to include(' _italic_ ')
      end

      it 'adds spaces around code markers' do
        content = '`code`'
        result = described_class.new(content, channel).render
        expect(result).to include(' `code` ')
      end
    end

    context 'when channel is Channel::Sms' do
      let(:channel) { instance_double(Channel::Sms, renderer: :render_plain_text) }

      it 'strips all markdown formatting' do
        content = '**bold** _italic_ `code`'
        result = described_class.new(content, channel).render
        expect(result.strip).to eq('bold italic code')
      end

      it 'preserves URLs from links in plain text format' do
        content = '[link text](https://example.com)'
        result = described_class.new(content, channel).render
        expect(result).to eq('link text https://example.com')
      end

      it 'preserves URLs in messages with multiple links' do
        content = 'Visit [our site](https://example.com) or [help center](https://help.example.com)'
        result = described_class.new(content, channel).render
        expect(result).to eq('Visit our site https://example.com or help center https://help.example.com')
      end

      it 'preserves link text and URL when both are present' do
        content = '[Reset password](https://example.com/reset)'
        result = described_class.new(content, channel).render
        expect(result).to eq('Reset password https://example.com/reset')
      end

      it 'handles complex markdown' do
        content = "# Heading\n\n**bold** _italic_ [link](https://example.com)"
        result = described_class.new(content, channel).render
        expect(result).to include('Heading')
        expect(result).to include('bold')
        expect(result).to include('italic')
        expect(result).to include('link https://example.com')
        expect(result).not_to include('**')
        expect(result).not_to include('_')
        expect(result).not_to include('[')
      end

      it 'preserves bullet list markers' do
        content = "- first item\n- second item\n- third item"
        result = described_class.new(content, channel).render
        expect(result).to include('- first item')
        expect(result).to include('- second item')
        expect(result).to include('- third item')
      end

      it 'preserves ordered list markers with numbering' do
        content = "1. first step\n2. second step\n3. third step"
        result = described_class.new(content, channel).render
        expect(result).to include('1. first step')
        expect(result).to include('2. second step')
        expect(result).to include('3. third step')
      end

      it 'preserves newlines in plain text without list markers' do
        content = "Line 1\nLine 2\nLine 3"
        result = described_class.new(content, channel).render
        expect(result).to include("Line 1\nLine 2\nLine 3")
        expect(result).not_to include('Line 1 Line 2')
      end

      it 'preserves multiple consecutive newlines for spacing' do
        content = "Para 1\n\n\n\nPara 2"
        result = described_class.new(content, channel).render
        expect(result.scan("\n").count).to eq(4)
        expect(result).to include("Para 1\n\n\n\nPara 2")
      end
    end

    context 'when channel is Channel::Telegram' do
      let(:channel) { instance_double(Channel::Telegram, renderer: :render_telegram_html) }

      it 'converts to HTML format' do
        content = '**bold** _italic_ `code`'
        result = described_class.new(content, channel).render
        expect(result).to include('<strong>bold</strong>')
        expect(result).to include('<em>italic</em>')
        expect(result).to include('<code>code</code>')
      end

      it 'handles links' do
        content = '[link text](https://example.com)'
        result = described_class.new(content, channel).render
        expect(result).to include('<a href="https://example.com">link text</a>')
      end

      it 'preserves single newlines' do
        content = "line 1\nline 2"
        result = described_class.new(content, channel).render
        expect(result).to include("\n")
        expect(result).to include("line 1\nline 2")
      end

      it 'preserves double newlines (paragraph breaks)' do
        content = "para 1\n\npara 2"
        result = described_class.new(content, channel).render
        expect(result.scan("\n").count).to eq(2)
        expect(result).to include("para 1\n\npara 2")
      end

      it 'preserves multiple consecutive newlines' do
        content = "para 1\n\n\n\npara 2"
        result = described_class.new(content, channel).render
        expect(result.scan("\n").count).to eq(4)
        expect(result).to include("para 1\n\n\n\npara 2")
      end

      it 'preserves newlines with varying amounts of whitespace between them' do
        content = "hello\n \n   \n     \n\t\nworld"
        result = described_class.new(content, channel).render
        expect(result.scan("\n").count).to be >= 5
        expect(result).to include('hello')
        expect(result).to include('world')
        expect(result.scan("\n").count).to be > 3
      end

      it 'converts strikethrough to HTML' do
        content = '~~strikethrough text~~'
        result = described_class.new(content, channel).render
        expect(result).to include('<del>strikethrough text</del>')
      end

      it 'converts blockquotes to HTML' do
        content = '> quoted text'
        result = described_class.new(content, channel).render
        expect(result).to include('<blockquote>')
        expect(result).to include('quoted text')
      end
    end

    context 'when channel is Channel::Email' do
      let(:channel) { instance_double(Channel::Email, renderer: :render_html) }

      it 'renders full HTML' do
        content = '**bold** _italic_'
        result = described_class.new(content, channel).render
        expect(result).to include('<strong>bold</strong>')
        expect(result).to include('<em>italic</em>')
      end

      it 'renders ordered lists as HTML' do
        content = "1. first\n2. second"
        result = described_class.new(content, channel).render
        expect(result).to include('<ol>')
        expect(result).to include('<li>first</li>')
      end

      it 'converts strikethrough to HTML' do
        content = '~~strikethrough text~~'
        result = described_class.new(content, channel).render
        expect(result).to include('<del>strikethrough text</del>')
      end
    end

    context 'when channel is Channel::WebWidget' do
      let(:channel) { instance_double(Channel::WebWidget, renderer: :render_html) }

      it 'renders full HTML like Email' do
        content = '**bold** _italic_ `code`'
        result = described_class.new(content, channel).render
        expect(result).to include('<strong>bold</strong>')
        expect(result).to include('<em>italic</em>')
        expect(result).to include('<code>code</code>')
      end

      it 'converts strikethrough to HTML' do
        content = '~~strikethrough text~~'
        result = described_class.new(content, channel).render
        expect(result).to include('<del>strikethrough text</del>')
      end
    end

    context 'when channel is Channel::FacebookPage' do
      let(:channel) { instance_double(Channel::FacebookPage, renderer: :render_instagram) }

      it 'converts bold to single asterisk like Instagram' do
        content = '**bold text**'
        result = described_class.new(content, channel).render
        expect(result.strip).to eq('*bold text*')
      end

      it 'strips unsupported formatting' do
        content = '`code` ~~strike~~'
        result = described_class.new(content, channel).render
        expect(result.strip).to eq('code ~~strike~~')
      end

      it 'preserves bullet list markers like Instagram' do
        content = "- first item\n- second item"
        result = described_class.new(content, channel).render
        expect(result).to include('- first item')
        expect(result).to include('- second item')
      end

      it 'preserves ordered list markers with numbering like Instagram' do
        content = "1. first step\n2. second step"
        result = described_class.new(content, channel).render
        expect(result).to include('1. first step')
        expect(result).to include('2. second step')
      end

      it 'renders code blocks as plain text' do
        content = "```\ncode here\n```"
        result = described_class.new(content, channel).render
        expect(result.strip).to eq('code here')
      end

      it 'handles code blocks with emojis and special characters without stack overflow' do
        content = "    first line\n    🌐 second line\n"
        result = described_class.new(content, channel).render
        expect(result).to eq("first line\n🌐 second line")
      end
    end

    context 'when channel is Channel::TwilioSms' do
      it 'strips all markdown like SMS when medium is sms' do
        content = '**bold** _italic_'
        channel = instance_double(Channel::TwilioSms, renderer: :render_plain_text)
        result = described_class.new(content, channel).render
        expect(result.strip).to eq('bold italic')
      end

      it 'uses WhatsApp renderer when medium is whatsapp' do
        content = '**bold** _italic_ [link](https://example.com)'
        channel = instance_double(Channel::TwilioSms, renderer: :render_whatsapp)
        result = described_class.new(content, channel).render
        expect(result.strip).to eq('*bold* _italic_ https://example.com')
      end

      it 'preserves newlines in Twilio WhatsApp' do
        content = "Line 1\nLine 2\nLine 3"
        channel = instance_double(Channel::TwilioSms, renderer: :render_whatsapp)
        result = described_class.new(content, channel).render
        expect(result).to include("Line 1\nLine 2\nLine 3")
      end

      it 'preserves ordered list markers with numbering in Twilio WhatsApp' do
        content = "1. first step\n2. second step\n3. third step"
        channel = instance_double(Channel::TwilioSms, renderer: :render_whatsapp)
        result = described_class.new(content, channel).render
        expect(result).to include('1. first step')
        expect(result).to include('2. second step')
        expect(result).to include('3. third step')
      end

      it 'preserves unordered list markers in Twilio WhatsApp' do
        content = "- item 1\n- item 2\n- item 3"
        channel = instance_double(Channel::TwilioSms, renderer: :render_whatsapp)
        result = described_class.new(content, channel).render
        expect(result).to include('- item 1')
        expect(result).to include('- item 2')
        expect(result).to include('- item 3')
      end

      it 'returns content as-is when no renderer is resolved' do
        content = '**bold** _italic_'
        channel = instance_double(Channel::TwilioSms, renderer: nil)
        result = described_class.new(content, channel).render
        expect(result).to eq(content)
      end
    end

    context 'when channel is Channel::Api' do
      let(:channel) { instance_double(Channel::Api, renderer: nil) }

      it 'preserves markdown as-is' do
        content = '**bold** _italic_ `code`'
        result = described_class.new(content, channel).render
        expect(result).to eq('**bold** _italic_ `code`')
      end

      it 'preserves links with markdown syntax' do
        content = '[Click here](https://example.com)'
        result = described_class.new(content, channel).render
        expect(result).to eq('[Click here](https://example.com)')
      end

      it 'preserves lists with markdown syntax' do
        content = "- Item 1\n- Item 2"
        result = described_class.new(content, channel).render
        expect(result).to eq("- Item 1\n- Item 2")
      end
    end

    context 'when channel is Channel::TwitterProfile' do
      let(:channel) { instance_double(Channel::TwitterProfile, renderer: :render_plain_text) }

      it 'strips all markdown like SMS' do
        content = '**bold** [link](https://example.com)'
        result = described_class.new(content, channel).render
        expect(result).to include('bold')
        expect(result).to include('link https://example.com')
        expect(result).not_to include('**')
        expect(result).not_to include('[')
      end

      it 'preserves URLs from links' do
        content = '[Reset password](https://example.com/reset)'
        result = described_class.new(content, channel).render
        expect(result).to eq('Reset password https://example.com/reset')
      end
    end

    context 'when testing all formatting types' do
      let(:channel) { instance_double(Channel::Whatsapp, renderer: :render_whatsapp) }

      it 'handles ordered lists with proper numbering' do
        content = "1. first\n2. second\n3. third"
        result = described_class.new(content, channel).render
        expect(result).to include('1. first')
        expect(result).to include('2. second')
        expect(result).to include('3. third')
      end
    end

    context 'when channel is unknown' do
      let(:channel) { nil }

      it 'returns content as-is' do
        content = '**bold** _italic_'
        result = described_class.new(content, channel).render
        expect(result).to eq(content)
      end
    end

    context 'when content has multiple newlines with whitespace between them' do
      let(:content_with_whitespace_newlines) { "hello   \n   \n   \n   \n   \n   \n   \n   \n   \n   \n   \n   \n   \n   \n   \n   \n \n\nhello wow" }

      {
        Channel::Telegram => :render_telegram_html,
        Channel::Whatsapp => :render_whatsapp,
        Channel::Instagram => :render_instagram,
        Channel::FacebookPage => :render_instagram,
        Channel::Line => :render_line,
        Channel::Sms => :render_plain_text
      }.each do |channel_class, renderer|
        context "when channel is #{channel_class}" do
          let(:channel) { instance_double(channel_class, renderer: renderer) }

          it 'normalizes whitespace-only lines and preserves multiple newlines' do
            result = described_class.new(content_with_whitespace_newlines, channel).render
            expect(result.scan("\n").count).to be >= 10
            expect(result.scan("\n").count).to be > 5
          end
        end
      end

      context 'when channel is Channel::TwilioSms with WhatsApp' do
        it 'normalizes whitespace-only lines and preserves multiple newlines' do
          channel = instance_double(Channel::TwilioSms, renderer: :render_whatsapp)
          result = described_class.new(content_with_whitespace_newlines, channel).render
          expect(result.scan("\n").count).to be >= 10
        end
      end
    end
  end
end
