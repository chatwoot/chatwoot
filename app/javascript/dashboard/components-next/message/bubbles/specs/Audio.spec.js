import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import AudioBubble from '../Audio.vue';
import { provideMessageContext } from '../../provider.js';
import { MESSAGE_VARIANTS, ORIENTATION } from '../../constants';

const mountAudio = variant => {
  const TestHost = defineComponent({
    components: { AudioBubble },
    setup() {
      provideMessageContext({
        attachments: ref([{ fileType: 'audio', dataUrl: 'audio.mp3' }]),
        variant: ref(variant),
        orientation: ref(ORIENTATION.RIGHT),
        contentAttributes: ref({}),
        additionalAttributes: ref({}),
        shouldGroupWithNext: ref(false),
        inReplyTo: ref(null),
        id: ref(1),
        sender: ref({}),
        senderType: ref('user'),
      });
    },
    template: '<AudioBubble />',
  });

  return mount(TestHost, {
    global: {
      stubs: {
        AudioChip: true,
        MessageMeta: true,
        ReferralCard: true,
        CaptainGenerationDetails: true,
      },
      mocks: { $t: key => key },
    },
  });
};

describe('Audio bubble', () => {
  it('keeps the private note amber, which is what marks it as internal', () => {
    const bubble = mountAudio(MESSAGE_VARIANTS.PRIVATE).find('div');

    expect(bubble.classes()).toContain('bg-n-solid-amber');
    // Tailwind emits .bg-transparent after every .bg-n-* utility at the same
    // specificity, so letting it through would silently win over the amber.
    expect(bubble.classes()).not.toContain('bg-transparent');
  });

  it('lets the chip stand on its own everywhere else', () => {
    const bubble = mountAudio(MESSAGE_VARIANTS.AGENT).find('div');

    expect(bubble.classes()).toContain('bg-transparent');
  });
});
