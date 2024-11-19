# frozen_string_literal: true

FactoryBot.define do
  factory :incoming_fb_text_message, class: Hash do
    messaging do
      { sender: { id: '3383290475046708' },
        recipient: { id: '117172741761305' },
        message: { mid: 'm_KXGKDUpO6xbVdAmZFBVpzU1AhKVJdAIUnUH4cwkvb_K3iZsWhowDRyJ_DcowEpJjncaBwdCIoRrixvCbbO1PcA', text: 'facebook message' } }
    end

    initialize_with { attributes }
  end

  factory :mocked_message_text, class: Hash do
    transient do
      sender_id { '3383290475046708' }
    end

    initialize_with do
      { messaging: { sender: { id: sender_id },
                     recipient: { id: '117172741761305' },
                     message: { mid: 'm_KXGKDUpO6xbVdAmZFBVpzU1AhKVJdAIUnUH4cwkvb_K3iZsWhowDRyJ_DcowEpJjncaBwdCIoRrixvCbbO1PcA',
                                text: 'facebook message' } } }
    end

    # initialize_with { attributes }
  end

  factory :message_deliveries, class: Hash do
    messaging do
      { sender: { id: '3383290475046708' },
        recipient: { id: '117172741761305' },
        delivery: { watermark: '1648581633369' } }
    end

    initialize_with { attributes }
  end

  factory :message_reads, class: Hash do
    messaging do
      { sender: { id: '3383290475046708' },
        recipient: { id: '117172741761305' },
        read: { watermark: '1648581633369' } }
    end

    initialize_with { attributes }
  end
end
