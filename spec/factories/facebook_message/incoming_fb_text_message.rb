# frozen_string_literal: true

FactoryBot.define do
  factory :incoming_fb_text_message, class: Hash do
    sender { { id: '3383290475046708' } }
    recipient { { id: '117172741761305' } }
    message { { mid: 'm_KXGKDUpO6xbVdAmZFBVpzU1AhKVJdAIUnUH4cwkvb_K3iZsWhowDRyJ_DcowEpJjncaBwdCIoRrixvCbbO1PcA', text: 'facebook message' } }
    text { 'facebook message' }

    initialize_with { attributes }
  end
end
