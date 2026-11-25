import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import VideoNoteBubble from '../VideoNote.vue';
import { provideMessageContext } from '../../provider.js';
import { MESSAGE_VARIANTS, ORIENTATION } from '../../constants';

// The state each case mounts in: loaded unless a case says otherwise.
const loadState = vi.hoisted(() => ({ isLoaded: true, hasError: false }));

vi.mock('dashboard/composables/loadWithRetry', async () => {
  const { ref: vueRef } = await import('vue');
  return {
    useLoadWithRetry: () => ({
      isLoaded: vueRef(loadState.isLoaded),
      hasError: vueRef(loadState.hasError),
      loadWithRetry: vi.fn(),
    }),
  };
});

beforeEach(() => {
  loadState.isLoaded = true;
  loadState.hasError = false;
});

vi.mock('dashboard/composables/store', async () => {
  const { ref: vueRef } = await import('vue');
  return { useMapGetter: () => vueRef([]) };
});

const mountVideoNote = (variant = MESSAGE_VARIANTS.USER) => {
  const TestHost = defineComponent({
    components: { VideoNoteBubble },
    setup() {
      provideMessageContext({
        filteredCurrentChatAttachments: ref([]),
        attachments: ref([
          { fileType: 'video', dataUrl: 'note.mp4', isVideoNote: true },
        ]),
        variant: ref(variant),
        orientation: ref(ORIENTATION.LEFT),
        contentAttributes: ref({}),
        additionalAttributes: ref({}),
        shouldGroupWithNext: ref(false),
        inReplyTo: ref(null),
        id: ref(1),
        sender: ref({}),
        senderType: ref('contact'),
      });
    },
    template: '<VideoNoteBubble />',
  });

  return mount(TestHost, {
    global: {
      stubs: {
        MessageMeta: true,
        ReferralCard: true,
        CaptainGenerationDetails: true,
        GalleryView: { template: '<div data-gallery />' },
      },
      mocks: { $t: key => key },
    },
  });
};

describe('VideoNote bubble', () => {
  it('plays the file inside a circle, with no bubble behind it', () => {
    const wrapper = mountVideoNote();

    const circle = wrapper.find('button');
    expect(circle.classes()).toContain('rounded-full');
    expect(circle.classes()).toContain('overflow-hidden');
    expect(circle.find('video').attributes('src')).toBe('note.mp4');
    expect(circle.find('video').classes()).toContain('object-cover');
    expect(wrapper.find('[data-bubble-name="video-note"]').classes()).toContain(
      'bg-transparent'
    );
  });

  // The circle's own click plays the note, so full size and download need a way in.
  it('opens the note in the gallery from its own button', async () => {
    const wrapper = mountVideoNote();
    expect(wrapper.find('[data-gallery]').exists()).toBe(false);

    await wrapper
      .find('[aria-label="COMPONENTS.MEDIA.OPEN_VIDEO_NOTE"]')
      .trigger('click');

    expect(wrapper.find('[data-gallery]').exists()).toBe(true);
  });

  // The gallery is the way to the file in every state of the bubble: still loading, and a
  // file this browser cannot decode but can still download.
  it.each([
    ['still loading', { isLoaded: false, hasError: false }],
    ['unplayable here', { isLoaded: false, hasError: true }],
  ])('offers the gallery while %s', async (_, state) => {
    Object.assign(loadState, state);
    const wrapper = mountVideoNote();

    await wrapper
      .find('[aria-label="COMPONENTS.MEDIA.OPEN_VIDEO_NOTE"]')
      .trigger('click');

    expect(wrapper.find('[data-gallery]').exists()).toBe(true);
  });

  // The gallery mounts a player of its own, so the circle behind it has to stop.
  it('pauses the circle before opening the gallery', async () => {
    const wrapper = mountVideoNote();
    const video = wrapper.find('video').element;
    video.pause = vi.fn();

    await wrapper
      .find('[aria-label="COMPONENTS.MEDIA.OPEN_VIDEO_NOTE"]')
      .trigger('click');

    expect(video.pause).toHaveBeenCalledTimes(1);
    expect(wrapper.find('[data-gallery]').exists()).toBe(true);
  });

  it('keeps the amber that marks a private note', () => {
    const bubble = mountVideoNote(MESSAGE_VARIANTS.PRIVATE).find(
      '[data-bubble-name="video-note"]'
    );

    expect(bubble.classes()).toContain('bg-n-solid-amber');
    expect(bubble.classes()).not.toContain('bg-transparent');
  });

  it('plays on a click and pauses on the next, as on the phone', async () => {
    const wrapper = mountVideoNote();
    const video = wrapper.find('video').element;
    let paused = true;
    Object.defineProperty(video, 'paused', { get: () => paused });
    video.play = vi.fn(() => {
      paused = false;
      return Promise.resolve();
    });
    video.pause = vi.fn(() => {
      paused = true;
    });

    expect(wrapper.find('button').attributes('aria-label')).toBe(
      'COMPONENTS.MEDIA.PLAY_VIDEO_NOTE'
    );
    await wrapper.find('button').trigger('click');
    expect(video.play).toHaveBeenCalledTimes(1);
    await wrapper.find('video').trigger('play');
    expect(wrapper.find('button').attributes('aria-label')).toBe(
      'COMPONENTS.MEDIA.PAUSE_VIDEO_NOTE'
    );

    await wrapper.find('button').trigger('click');
    expect(video.pause).toHaveBeenCalledTimes(1);
  });

  it('keeps the play control when the browser refuses to play', async () => {
    const wrapper = mountVideoNote();
    const video = wrapper.find('video').element;
    Object.defineProperty(video, 'paused', { get: () => true });
    // A refusal changes nothing on the element and fires no error event. A plain function,
    // not vi.fn, because a spy handles the promise itself to record its result, and an
    // unhandled rejection is what fails this case.
    video.play = () =>
      Promise.reject(new DOMException('refused', 'NotAllowedError'));

    await wrapper.find('button').trigger('click');
    await new Promise(resolve => {
      setTimeout(resolve, 0);
    });

    expect(wrapper.find('button').attributes('aria-label')).toBe(
      'COMPONENTS.MEDIA.PLAY_VIDEO_NOTE'
    );
  });
});
