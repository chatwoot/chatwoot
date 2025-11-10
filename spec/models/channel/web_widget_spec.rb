# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Channel::WebWidget do
  context 'when
  web widget channel' do
    let!(:channel_widget) { create(:channel_widget) }

    it 'pre chat options' do
      expect(channel_widget.pre_chat_form_options['pre_chat_message']).to eq 'Share your queries or comments here.'
      expect(channel_widget.pre_chat_form_options['pre_chat_fields'].length).to eq 3
    end
  end

  describe 'EDITABLE_ATTRS' do
    it 'includes the expected attributes' do
      expected_attrs = [
        :website_url,
        :widget_color,
        :welcome_title,
        :welcome_tagline,
        :reply_time,
        :pre_chat_form_enabled,
        :continuity_via_email,
        :hmac_mandatory,
        :allowed_domains,
        :auto_generate_landing_page,
        :landing_page_description,
        :landing_page_url
      ]

      expected_attrs.each do |attr|
        expect(Channel::WebWidget::EDITABLE_ATTRS).to include(attr)
      end
    end

    it 'includes pre_chat_form_options hash' do
      pre_chat_options = Channel::WebWidget::EDITABLE_ATTRS.find { |attr| attr.is_a?(Hash) && attr.key?(:pre_chat_form_options) }
      expect(pre_chat_options).to be_present
      expect(pre_chat_options[:pre_chat_form_options]).to include(:pre_chat_message, :require_email)
      expect(pre_chat_options[:pre_chat_form_options]).to include(hash_including(:pre_chat_fields))
    end

    it 'includes selected_feature_flags array' do
      feature_flags = Channel::WebWidget::EDITABLE_ATTRS.find { |attr| attr.is_a?(Hash) && attr.key?(:selected_feature_flags) }
      expect(feature_flags).to be_present
      expect(feature_flags[:selected_feature_flags]).to eq([])
    end

    it 'is frozen' do
      expect(Channel::WebWidget::EDITABLE_ATTRS).to be_frozen
    end
  end
end
