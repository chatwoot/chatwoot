require 'rails_helper'

describe MessageFormatHelper, type: :helper do
  describe '#transform_user_mention_content' do
    context 'when transform_user_mention_content called' do
      it 'return transormed text correctly' do
        expect(helper.transform_user_mention_content('[@john](mention://user/1/John%20K), check this ticket')).to eq '@john, check this ticket'
      end
    end
  end
end
