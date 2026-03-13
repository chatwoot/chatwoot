import { mount } from '@vue/test-utils';
import { vi } from 'vitest';
import ReplyBottomPanel from '../ReplyBottomPanel.vue';

vi.mock('dashboard/composables/useUISettings', () => ({
  useUISettings: () => ({
    setSignatureFlagForInbox: vi.fn(),
    fetchSignatureFlagFromUISettings: vi.fn(() => false),
  }),
}));

vi.mock('dashboard/composables/useKeyboardEvents', () => ({
  useKeyboardEvents: vi.fn(),
}));

describe('ReplyBottomPanel.vue', () => {
  const buildWrapper = (props = {}) =>
    mount(ReplyBottomPanel, {
      props: {
        conversationId: 1,
        inbox: {},
        portalSlug: 'help',
        ...props,
      },
      global: {
        mocks: {
          $t: key => key,
          $store: {
            getters: {
              getCurrentAccountId: 1,
              'accounts/isFeatureEnabledonAccount': () => false,
              'integrations/getUIFlags': {},
            },
          },
        },
        stubs: {
          NextButton: {
            props: [
              'label',
              'icon',
              'variant',
              'color',
              'slate',
              'faded',
              'sm',
            ],
            template:
              '<button :data-icon="icon" :data-label="label" :data-variant="variant" :data-color="color" @click="$emit(\'click\')"><slot /></button>',
          },
          FileUpload: {
            template: '<div><slot /></div>',
          },
          VideoCallButton: true,
          FluentIcon: true,
        },
      },
    });

  it('renders and emits the plain text toggle in normal reply mode', async () => {
    const wrapper = buildWrapper();

    const toggleButton = wrapper
      .findAll('button')
      .find(node => node.attributes('data-label') === 'TXT');

    expect(toggleButton).toBeTruthy();
    expect(toggleButton.attributes('data-variant')).toBe('faded');

    await toggleButton.trigger('click');

    expect(wrapper.emitted('togglePlainTextMode')?.length).toBeGreaterThan(0);
  });

  it('hides the plain text toggle on private notes', () => {
    const wrapper = buildWrapper({
      isOnPrivateNote: true,
    });

    const toggleButton = wrapper
      .findAll('button')
      .find(node => node.attributes('data-label') === 'TXT');

    expect(toggleButton).toBeUndefined();
  });
});
