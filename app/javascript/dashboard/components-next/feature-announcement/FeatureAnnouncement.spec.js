import { nextTick } from 'vue';
import { mount } from '@vue/test-utils';
import FeatureAnnouncement from './FeatureAnnouncement.vue';

const testState = vi.hoisted(() => ({
  updateUISettings: vi.fn(),
  swipeOptions: null,
}));

vi.mock('dashboard/composables/store', async () => {
  const { computed, ref } = await import('vue');
  testState.announcements = ref([]);
  testState.isRTL = ref(false);
  const globalConfig = computed(() => ({
    activeFeatureAnnouncements: testState.announcements.value,
  }));

  return {
    useMapGetter: key =>
      ({ 'globalConfig/get': globalConfig, 'accounts/isRTL': testState.isRTL })[
        key
      ],
  };
});

vi.mock('dashboard/composables/useUISettings', async () => {
  const { ref } = await import('vue');
  testState.uiSettings = ref({});

  return {
    useUISettings: () => ({
      uiSettings: testState.uiSettings,
      updateUISettings: testState.updateUISettings,
    }),
  };
});

vi.mock('@vueuse/core', async () => {
  const { reactive: createReactive } = await import('vue');
  return {
    useScroll: () => ({
      arrivedState: createReactive({ left: true, right: true, bottom: true }),
      measure: vi.fn(),
    }),
    useSwipe: (_, options) => {
      testState.swipeOptions = options;
    },
  };
});

const ButtonStub = {
  props: ['label', 'disabled'],
  template: '<button type="button" :disabled="disabled">{{ label }}</button>',
};

const dompurifyHtml = {
  mounted: (el, { value }) => {
    el.innerHTML = value;
  },
  updated: (el, { value }) => {
    el.innerHTML = value;
  },
};

const mountComponent = () =>
  mount(FeatureAnnouncement, {
    attachTo: document.body,
    global: {
      stubs: { Button: ButtonStub, Icon: true, I18nT: true },
      directives: { 'dompurify-html': dompurifyHtml },
    },
  });

const automations = {
  id: 2,
  title: 'Automations that run on their own',
  banner_message: 'Stop doing the same clicks.\n\n- Assign to a team',
  video_url: 'https://www.youtube.com/watch?v=DTsOaE40d8o',
  updated_at: '2026-09-29T10:00:00.000Z',
};

const macros = {
  id: 5,
  title: 'Speed through support with macros',
  banner_message: 'Bundle a sequence of actions into one macro.',
  video_url: 'https://www.youtube.com/watch?v=S3riosQbhKs',
  updated_at: '2026-09-29T11:00:00.000Z',
};

const voiceCalls = {
  id: 6,
  title: 'Introducing voice calls',
  banner_message: 'Take and make phone calls without leaving the inbox.',
  video_url: 'https://youtu.be/h_ei5H44BL8',
  updated_at: '2026-09-29T12:00:00.000Z',
};

const currentTitle = wrapper => wrapper.find('h1').text();
const thumbnails = wrapper => wrapper.findAll('.no-scrollbar button');
const dots = wrapper => wrapper.findAll('button.p-2');
const footerButton = (wrapper, label) =>
  wrapper
    .findAll(`button[aria-label="FEATURE_ANNOUNCEMENT.${label}"]`)
    .find(button => button.element.closest('.border-t'));

describe('FeatureAnnouncement', () => {
  beforeEach(() => {
    HTMLDialogElement.prototype.showModal = vi.fn();
    Element.prototype.scrollBy = vi.fn();
    testState.announcements.value = [voiceCalls, macros, automations];
    testState.isRTL.value = false;
    testState.uiSettings.value = {};
  });

  it('renders nothing when there are no announcements', () => {
    testState.announcements.value = [];

    expect(mountComponent().find('dialog').exists()).toBe(false);
  });

  it('renders nothing when every announcement is dismissed', () => {
    testState.uiSettings.value = {
      dismissed_feature_announcements: [
        '6-2026-09-29T12:00:00.000Z',
        '5-2026-09-29T11:00:00.000Z',
        '2-2026-09-29T10:00:00.000Z',
      ],
    };

    expect(mountComponent().find('dialog').exists()).toBe(false);
  });

  it('shows an announcement again once it has been updated', () => {
    testState.announcements.value = [automations];
    testState.uiSettings.value = {
      dismissed_feature_announcements: ['2-2026-09-28T10:00:00.000Z'],
    };

    expect(currentTitle(mountComponent())).toBe(automations.title);
  });

  it('opens on the newest announcement with its video and content', async () => {
    const wrapper = mountComponent();
    await nextTick();

    expect(HTMLDialogElement.prototype.showModal).toHaveBeenCalled();
    expect(currentTitle(wrapper)).toBe(voiceCalls.title);
    expect(wrapper.find('iframe').attributes('src')).toBe(
      'https://www.youtube-nocookie.com/embed/h_ei5H44BL8'
    );
    expect(wrapper.find('img').attributes('src')).toBe(
      'https://i.ytimg.com/vi/h_ei5H44BL8/mqdefault.jpg'
    );
  });

  it('renders the description as markdown', () => {
    testState.announcements.value = [automations];
    const wrapper = mountComponent();

    expect(wrapper.find('h1 + div li').text()).toBe('Assign to a team');
  });

  it('binds the player URL instead of rendering template markup', () => {
    testState.announcements.value = [
      {
        ...automations,
        video_url: 'https://youtu.be/abc"><img src=x onerror=1>',
      },
    ];
    const wrapper = mountComponent();

    expect(wrapper.findAll('iframe')).toHaveLength(1);
    expect(wrapper.find('img[onerror]').exists()).toBe(false);
  });

  it('plays direct video files with a native player', () => {
    testState.announcements.value = [
      { ...macros, video_url: 'https://cdn.example.com/macros.mp4' },
    ];
    const wrapper = mountComponent();

    expect(wrapper.find('video').attributes('src')).toBe(
      'https://cdn.example.com/macros.mp4'
    );
    expect(wrapper.find('iframe').exists()).toBe(false);
  });

  it('falls back to the line texture for videos without a thumbnail', () => {
    testState.announcements.value = [
      { ...macros, video_url: 'https://vimeo.com/000000000' },
    ];
    const wrapper = mountComponent();

    expect(wrapper.find('iframe').attributes('src')).toBe(
      'https://player.vimeo.com/video/000000000?dnt=true'
    );
    expect(wrapper.find('img').exists()).toBe(false);
    expect(wrapper.find('[aria-hidden="true"]').exists()).toBe(true);
  });

  it('hides the switcher for a single announcement', () => {
    testState.announcements.value = [automations];
    const wrapper = mountComponent();

    expect(thumbnails(wrapper)).toHaveLength(0);
    expect(dots(wrapper)).toHaveLength(0);
    expect(wrapper.findComponent({ name: 'I18nT' }).exists()).toBe(true);
  });

  it('switches announcements from the thumbnails, dots and arrows', async () => {
    const wrapper = mountComponent();

    expect(thumbnails(wrapper)).toHaveLength(3);
    expect(footerButton(wrapper, 'PREVIOUS').attributes('disabled')).toBe('');

    await thumbnails(wrapper)[1].trigger('click');
    expect(currentTitle(wrapper)).toBe(macros.title);
    expect(thumbnails(wrapper)[1].attributes('aria-current')).toBe('true');
    expect(dots(wrapper)[1].attributes('aria-current')).toBe('true');

    await footerButton(wrapper, 'NEXT').trigger('click');
    expect(currentTitle(wrapper)).toBe(automations.title);
    expect(footerButton(wrapper, 'NEXT').attributes('disabled')).toBe('');

    await dots(wrapper)[0].trigger('click');
    expect(currentTitle(wrapper)).toBe(voiceCalls.title);
  });

  it('scrolls only the thumbnail strip to the current announcement', async () => {
    const wrapper = mountComponent();

    await thumbnails(wrapper)[2].trigger('click');
    await nextTick();

    const stripElement = wrapper.find('.no-scrollbar').element;
    expect(Element.prototype.scrollBy).toHaveBeenCalledTimes(1);
    expect(Element.prototype.scrollBy.mock.instances[0]).toBe(stripElement);
  });

  it('slides a window of seven dots across long playlists', async () => {
    testState.announcements.value = Array.from({ length: 12 }, (_, index) => ({
      ...automations,
      id: index + 1,
      title: `Announcement ${index + 1}`,
    }));
    const wrapper = mountComponent();

    expect(dots(wrapper)).toHaveLength(7);
    expect(dots(wrapper)[0].attributes('aria-current')).toBe('true');

    await thumbnails(wrapper)[11].trigger('click');
    expect(dots(wrapper)).toHaveLength(7);
    expect(dots(wrapper)[6].attributes('aria-label')).toBe('Announcement 12');
    expect(dots(wrapper)[6].attributes('aria-current')).toBe('true');

    await thumbnails(wrapper)[5].trigger('click');
    expect(dots(wrapper)[0].attributes('aria-label')).toBe('Announcement 3');
    expect(dots(wrapper)[3].attributes('aria-current')).toBe('true');
  });

  it('switches announcements with the arrow keys', async () => {
    const wrapper = mountComponent();
    const dialog = wrapper.find('dialog');

    await dialog.trigger('keydown', { key: 'ArrowRight' });
    expect(currentTitle(wrapper)).toBe(macros.title);

    await dialog.trigger('keydown', { key: 'ArrowLeft' });
    expect(currentTitle(wrapper)).toBe(voiceCalls.title);

    await dialog.trigger('keydown', { key: 'ArrowLeft' });
    expect(currentTitle(wrapper)).toBe(voiceCalls.title);
  });

  it('reverses the arrow keys in RTL', async () => {
    testState.isRTL.value = true;
    const wrapper = mountComponent();

    await wrapper.find('dialog').trigger('keydown', { key: 'ArrowLeft' });

    expect(currentTitle(wrapper)).toBe(macros.title);
  });

  it('switches announcements on swipe outside the thumbnail strip', async () => {
    const wrapper = mountComponent();

    testState.swipeOptions.onSwipeEnd(
      { target: wrapper.find('h1').element },
      'left'
    );
    await nextTick();
    expect(currentTitle(wrapper)).toBe(macros.title);

    testState.swipeOptions.onSwipeEnd(
      { target: thumbnails(wrapper)[0].element },
      'right'
    );
    await nextTick();
    expect(currentTitle(wrapper)).toBe(macros.title);
  });

  it('marks every active announcement as dismissed on close', async () => {
    const wrapper = mountComponent();

    await wrapper
      .find('button[aria-label="FEATURE_ANNOUNCEMENT.CLOSE"]')
      .trigger('click');

    expect(testState.updateUISettings).toHaveBeenCalledWith({
      dismissed_feature_announcements: [
        '6-2026-09-29T12:00:00.000Z',
        '5-2026-09-29T11:00:00.000Z',
        '2-2026-09-29T10:00:00.000Z',
      ],
    });
  });

  it('dismisses when the dialog closes from the keyboard', async () => {
    const wrapper = mountComponent();

    await wrapper.find('dialog').trigger('close');

    expect(testState.updateUISettings).toHaveBeenCalledTimes(1);
  });

  it('hides the panel once the dismissal is stored', async () => {
    const wrapper = mountComponent();

    testState.uiSettings.value = {
      dismissed_feature_announcements: [
        '6-2026-09-29T12:00:00.000Z',
        '5-2026-09-29T11:00:00.000Z',
        '2-2026-09-29T10:00:00.000Z',
      ],
    };
    await nextTick();

    expect(wrapper.find('dialog').exists()).toBe(false);
  });
});
