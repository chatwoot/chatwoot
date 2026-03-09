require 'rails_helper'

describe MessageFormatHelper do
  describe '#transform_user_mention_content' do
    context 'when transform_user_mention_content called' do
      it 'return transormed text correctly' do
        expect(helper.transform_user_mention_content('[@john](mention://user/1/John%20K), check this ticket')).to eq '@john, check this ticket'
      end
    end
  end

  describe '#render_message_content' do
    context 'when render_message_content called' do
      it 'render text correctly' do
        expect(helper.render_message_content('Hi *there*, I am mostly text!')).to eq "<p>Hi <em>there</em>, I am mostly text!</p>\n"
      end
    end
  end
end
