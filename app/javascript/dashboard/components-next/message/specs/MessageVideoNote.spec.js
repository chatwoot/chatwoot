import { ref } from 'vue';
import { shallowMount, config } from '@vue/test-utils';
import Message from '../Message.vue';
import VideoBubble from '../bubbles/Video.vue';
import VideoNoteBubble from '../bubbles/VideoNote.vue';
import ContextMenu from 'dashboard/modules/conversations/components/MessageContextMenu.vue';

vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('vue-router', () => ({
  useRoute: () => ({ params: {}, query: {} }),
  useRouter: () => ({ push: vi.fn() }),
}));
vi.mock('dashboard/composables', () => ({ useTrack: vi.fn() }));
vi.mock('dashboard/composables/loadWithRetry', async () => {
  const { ref: vueRef } = await import('vue');
  return {
    useLoadWithRetry: () => ({
      isLoaded: vueRef(true),
      hasError: vueRef(false),
      loadWithRetry: vi.fn(),
    }),
  };
});
vi.mock('dashboard/composables/store', () => ({
  useMapGetter: name =>
    name === 'getCurrentUser' ? ref({ accounts: [] }) : ref(() => ({})),
  useStore: () => ({ dispatch: vi.fn(), getters: {} }),
}));
vi.mock('dashboard/composables/useTranslations', () => ({
  useTranslations: () => ({ translationContent: ref(null) }),
}));
vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({ accountId: ref(1), currentAccount: ref({}) }),
}));

// The dashboard camelizes the API payload before it reaches Message.vue, so the flag
// arrives as `isVideoNote` on the attachment, and only a flagged video plays in a circle.
const mountWith = attachment =>
  shallowMount(Message, {
    props: {
      id: 1,
      messageType: 0,
      conversationId: 1,
      createdAt: 1795549864,
      currentUserId: 1,
      attachments: [attachment],
      content: null,
      sender: { id: 2, type: 'contact', name: 'Contato' },
      senderType: 'Contact',
    },
    global: { mocks: { $t: key => key } },
  });

describe('Message picking the bubble for a video', () => {
  it('plays a video note in the circle', () => {
    const wrapper = mountWith({
      fileType: 'video',
      dataUrl: 'note.mp4',
      isVideoNote: true,
    });

    expect(wrapper.findComponent(VideoNoteBubble).exists()).toBe(true);
    expect(wrapper.findComponent(VideoBubble).exists()).toBe(false);
  });

  it('keeps an ordinary video in the regular player', () => {
    const wrapper = mountWith({ fileType: 'video', dataUrl: 'clip.mp4' });

    expect(wrapper.findComponent(VideoBubble).exists()).toBe(true);
    expect(wrapper.findComponent(VideoNoteBubble).exists()).toBe(false);
  });

  // The circle has no native controls and no padding around it, so a right-click on the
  // video itself is the way to the message's menu: reply, copy link, delete.
  it('opens the message menu from a right-click on the circle', async () => {
    config.global.renderStubDefaultSlot = true;
    try {
      const wrapper = shallowMount(Message, {
        props: {
          id: 1,
          messageType: 0,
          conversationId: 1,
          createdAt: 1795549864,
          currentUserId: 1,
          attachments: [
            { fileType: 'video', dataUrl: 'note.mp4', isVideoNote: true },
          ],
          content: null,
          sender: { id: 2, type: 'contact', name: 'Contato' },
          senderType: 'Contact',
        },
        global: {
          mocks: { $t: key => key },
          stubs: {
            VideoNote: false,
            VideoNoteBubble: false,
            Base: false,
            BaseBubble: false,
          },
        },
      });
      await wrapper.find('video').trigger('contextmenu');

      expect(wrapper.findComponent(ContextMenu).props('isOpen')).toBe(true);
    } finally {
      config.global.renderStubDefaultSlot = false;
    }
  });
});
