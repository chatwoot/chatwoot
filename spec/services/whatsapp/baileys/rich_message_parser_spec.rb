require 'rails_helper'

describe Whatsapp::Baileys::RichMessageParser do
  def parse(msg)
    described_class.new(msg).parse
  end

  def text_for(msg)
    described_class.to_text(described_class.new(msg).parse)
  end

  describe '.rich?' do
    it 'detects every rich/response key' do
      %i[interactiveMessage templateMessage buttonsMessage listMessage
         buttonsResponseMessage listResponseMessage templateButtonReplyMessage interactiveResponseMessage].each do |key|
        expect(described_class.rich?({ key => {} })).to be(true)
      end
    end

    it 'is false for a plain text message' do
      expect(described_class.rich?({ conversation: 'hi' })).to be(false)
    end
  end

  describe 'templateMessage' do
    it 'renders the body only (real hydratedTemplate shape)' do
      msg = { templateMessage: { hydratedTemplate: { hydratedTitleText: '', hydratedContentText: 'Your plan expires soon' } } }

      expect(parse(msg)).to eq(type: 'template', body: 'Your plan expires soon')
      expect(text_for(msg)).to eq('Your plan expires soon')
    end

    it 'renders body + footer + quick-reply button (real shape)' do
      msg = { templateMessage: { hydratedTemplate: {
        hydratedContentText: 'Renew?', hydratedFooterText: 'Acme',
        hydratedButtons: [{ quickReplyButton: { displayText: 'Renew now!', id: 'renew' }, index: 0 }]
      } } }

      expect(text_for(msg)).to eq("Renew?\n\nAcme\n\n▸ Renew now!")
    end

    it 'includes the url and phone of url/call buttons (hydratedFourRowTemplate)' do
      msg = { templateMessage: { hydratedFourRowTemplate: {
        hydratedContentText: 'Invoice',
        hydratedButtons: [
          { urlButton: { displayText: 'Pay now', url: 'https://acme.io/pay' } },
          { callButton: { displayText: 'Call us', phoneNumber: '+5511999999999' } }
        ]
      } } }

      expect(parse(msg)[:buttons]).to eq(
        [{ text: 'Pay now', url: 'https://acme.io/pay' }, { text: 'Call us', phone: '+5511999999999' }]
      )
      expect(text_for(msg)).to eq("Invoice\n\n▸ Pay now: https://acme.io/pay\n\n▸ Call us: +5511999999999")
    end

    it 'returns nil for an empty template (only media header / no text)' do
      expect(parse({ templateMessage: { hydratedTemplate: { templateId: '1' } } })).to be_nil
    end
  end

  describe 'interactiveMessage (nativeFlow)' do
    it 'parses a cta_url button from the snake_case JSON string' do
      msg = { interactiveMessage: {
        body: { text: 'Pick one' },
        nativeFlowMessage: { buttons: [{ name: 'cta_url', buttonParamsJson: '{"display_text":"Buy","url":"https://b.io"}' }] }
      } }

      expect(parse(msg)).to eq(type: 'interactive', body: 'Pick one', buttons: [{ text: 'Buy', url: 'https://b.io' }])
      expect(text_for(msg)).to eq("Pick one\n\n▸ Buy: https://b.io")
    end

    it 'parses a cta_call button phone number' do
      msg = { interactiveMessage: {
        nativeFlowMessage: { buttons: [{ name: 'cta_call', buttonParamsJson: '{"display_text":"Call","phone_number":"+551130000000"}' }] }
      } }

      expect(parse(msg)[:buttons]).to eq([{ text: 'Call', phone: '+551130000000' }])
    end

    it 'expands a single_select into one button per row' do
      params = { title: 'Ver opções', sections: [{ title: 'Bebidas', rows: [{ title: 'Coca' }, { title: 'Água' }] }] }
      msg = { interactiveMessage: {
        body: { text: 'Escolha' },
        nativeFlowMessage: { buttons: [{ name: 'single_select', buttonParamsJson: params.to_json }] }
      } }

      expect(parse(msg)[:buttons]).to eq([{ text: 'Coca' }, { text: 'Água' }])
    end

    it 'reads the url of an open_webview button from link.url' do
      params = { title: 'Abrir', link: { url: 'https://w.io', in_app_webview: true } }
      msg = { interactiveMessage: { nativeFlowMessage: { buttons: [{ name: 'open_webview', buttonParamsJson: params.to_json }] } } }

      expect(parse(msg)[:buttons]).to eq([{ text: 'Abrir', url: 'https://w.io' }])
    end

    it 'falls back to flow_cta for a flow button label' do
      msg = { interactiveMessage: { nativeFlowMessage: { buttons: [{ name: 'flow', buttonParamsJson: '{"flow_cta":"Agendar"}' }] } } }

      expect(parse(msg)[:buttons]).to eq([{ text: 'Agendar' }])
    end

    it 'degrades to the body when buttonParamsJson is malformed' do
      msg = { interactiveMessage: {
        body: { text: 'Pick' },
        nativeFlowMessage: { buttons: [{ name: 'cta_url', buttonParamsJson: 'not-json' }] }
      } }

      expect(parse(msg)).to eq(type: 'interactive', body: 'Pick')
      expect(text_for(msg)).to eq('Pick')
    end

    it 'degrades to the body when buttonParamsJson is a non-string (TypeError)' do
      msg = { interactiveMessage: {
        body: { text: 'Pick' },
        nativeFlowMessage: { buttons: [{ name: 'cta_url', buttonParamsJson: { display_text: 'Buy' } }] }
      } }

      expect(parse(msg)).to eq(type: 'interactive', body: 'Pick')
    end

    it 'degrades to the body when buttonParamsJson is valid JSON but not an object' do
      msg = { interactiveMessage: {
        body: { text: 'Pick' },
        nativeFlowMessage: { buttons: [{ name: 'cta_url', buttonParamsJson: '[1,2,3]' }] }
      } }

      expect(parse(msg)).to eq(type: 'interactive', body: 'Pick')
    end

    # Real WABA shape: an InteractiveMessage nested under templateMessage.
    it 'parses an interactive template (templateMessage.interactiveMessageTemplate)' do
      msg = { templateMessage: { interactiveMessageTemplate: {
        body: { text: 'Baixe o app!' },
        nativeFlowMessage: { buttons: [
          { name: 'cta_url', buttonParamsJson: '{"display_text":"Baixar no iOS","url":"https://apps.apple.com/x"}' },
          { name: 'cta_url', buttonParamsJson: '{"display_text":"Baixar no Android","url":"https://play.google.com/x"}' }
        ] }
      } } }

      expect(parse(msg)).to eq(type: 'interactive', body: 'Baixe o app!', buttons: [
                                 { text: 'Baixar no iOS', url: 'https://apps.apple.com/x' },
                                 { text: 'Baixar no Android', url: 'https://play.google.com/x' }
                               ])
    end
  end

  describe 'buttonsMessage' do
    it 'renders content + button labels' do
      msg = { buttonsMessage: {
        contentText: 'Choose', footerText: 'footer',
        buttons: [{ buttonText: { displayText: 'Yes' } }, { buttonText: { displayText: 'No' } }]
      } }

      expect(text_for(msg)).to eq("Choose\n\nfooter\n\n▸ Yes\n\n▸ No")
    end
  end

  describe 'listMessage' do
    it 'renders title/description + section rows' do
      msg = { listMessage: {
        title: 'Menu', description: 'Pick one', buttonText: 'Open',
        sections: [{ title: 'Drinks', rows: [{ title: 'Coke', rowId: 'c' }, { title: 'Water', rowId: 'w' }] }]
      } }

      expect(parse(msg)[:buttons]).to eq([{ text: 'Coke' }, { text: 'Water' }])
      expect(text_for(msg)).to eq("Menu\n\nPick one\n\n▸ Coke\n\n▸ Water")
    end
  end

  describe 'pollCreationMessage' do
    it 'renders the question and options (real shape)' do
      msg = { pollCreationMessage: { name: 'Pergunta?', options: [{ optionName: 'Opção 1' }, { optionName: 'Opção 2' }],
                                     selectableOptionsCount: 0 } }

      expect(parse(msg)).to eq(type: 'poll', title: 'Pergunta?', buttons: [{ text: 'Opção 1' }, { text: 'Opção 2' }])
      expect(text_for(msg)).to eq("Pergunta?\n\n▸ Opção 1\n\n▸ Opção 2")
    end

    it 'handles the V2/V3 keys' do
      msg = { pollCreationMessageV3: { name: 'Q', options: [{ optionName: 'A' }] } }
      expect(parse(msg)[:type]).to eq('poll')
    end
  end

  describe 'response variants' do
    it 'reads the selected text of each response shape' do
      expect(text_for({ buttonsResponseMessage: { selectedDisplayText: 'Yes' } })).to eq('Yes')
      expect(text_for({ listResponseMessage: { title: 'Coke', singleSelectReply: { selectedRowId: 'c' } } })).to eq('Coke')
      expect(text_for({ templateButtonReplyMessage: { selectedDisplayText: 'Pay now' } })).to eq('Pay now')
      expect(text_for({ interactiveResponseMessage: { body: { text: 'Done' } } })).to eq('Done')
    end
  end

  describe 'unknown / empty rich shapes' do
    it 'returns nil so the caller marks the message unsupported' do
      expect(parse({ interactiveMessage: {} })).to be_nil
      expect(parse({ buttonsResponseMessage: {} })).to be_nil
      expect(described_class.to_text(nil)).to be_nil
    end
  end

  describe '#context_info' do
    it 'returns the contextInfo of the rich subtype (for externalAdReply)' do
      ctx = { externalAdReply: { title: 'Ad' } }
      expect(described_class.new({ templateMessage: { contextInfo: ctx } }).context_info).to eq(ctx)
      expect(described_class.new({ interactiveMessage: { contextInfo: ctx } }).context_info).to eq(ctx)
    end

    it 'reads the contextInfo nested in an interactiveMessageTemplate (real WABA shape)' do
      ctx = { externalAdReply: { title: 'Ad' }, stanzaId: 'QUOTED_1' }
      expect(described_class.new({ templateMessage: { interactiveMessageTemplate: { contextInfo: ctx } } }).context_info).to eq(ctx)
    end
  end

  describe '#media_header' do
    def header_for(msg)
      described_class.new(msg).media_header
    end

    it 'finds a document in a template header (and maps it to :file)' do
      node = { url: 'https://x/inv.pdf', mimetype: 'application/pdf', fileName: 'inv.pdf' }
      expect(header_for({ templateMessage: { hydratedTemplate: { documentMessage: node } } }))
        .to eq(kind: 'file', node: node)
    end

    it 'finds an image in a hydratedFourRowTemplate header' do
      node = { url: 'https://x/i.jpg', mimetype: 'image/jpeg' }
      expect(header_for({ templateMessage: { hydratedFourRowTemplate: { imageMessage: node } } }))
        .to eq(kind: 'image', node: node)
    end

    it 'finds a video in an interactive header and an image in a buttons header' do
      vid = { url: 'https://x/v.mp4', mimetype: 'video/mp4' }
      img = { url: 'https://x/i.jpg', mimetype: 'image/jpeg' }
      expect(header_for({ interactiveMessage: { header: { videoMessage: vid } } })).to eq(kind: 'video', node: vid)
      expect(header_for({ buttonsMessage: { imageMessage: img } })).to eq(kind: 'image', node: img)
    end

    it 'finds the video header nested in an interactiveMessageTemplate (real WABA shape)' do
      vid = { url: 'https://x/v.enc', mimetype: 'video/mp4' }
      msg = { templateMessage: { interactiveMessageTemplate: { header: { hasMediaAttachment: true, videoMessage: vid } } } }
      expect(header_for(msg)).to eq(kind: 'video', node: vid)
    end

    it 'is nil when there is no header media' do
      expect(header_for({ templateMessage: { hydratedTemplate: { hydratedContentText: 'hi' } } })).to be_nil
    end

    it 'is exposed even for a media-only template whose #parse is nil' do
      msg = { templateMessage: { hydratedTemplate: { documentMessage: { mimetype: 'application/pdf' } } } }
      expect(parse(msg)).to be_nil
      expect(header_for(msg)).to include(kind: 'file')
    end
  end
end
