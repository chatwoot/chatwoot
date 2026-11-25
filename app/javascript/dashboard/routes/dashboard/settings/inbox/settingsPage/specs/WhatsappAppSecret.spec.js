import { describe, it, expect, beforeEach, vi } from 'vitest';
import { defineComponent, h, nextTick } from 'vue';
import { mount, flushPromises } from '@vue/test-utils';
import WhatsappAppSecret from '../WhatsappAppSecret.vue';

const mockDispatch = vi.fn();
vi.mock('vuex', () => ({ useStore: () => ({ dispatch: mockDispatch }) }));

vi.mock('vue-i18n', async () => {
  const actual = await vi.importActual('vue-i18n');
  return { ...actual, useI18n: () => ({ t: key => key }) };
});

const mockAlert = vi.fn();
vi.mock('dashboard/composables', () => ({
  useAlert: (...args) => mockAlert(...args),
}));

const SECRET_INPUT =
  'input[placeholder="INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_APP_SECRET.PLACEHOLDER"]';

const INBOX = {
  id: 7,
  provider: 'whatsapp_cloud',
  provider_config: { api_key: 'token', source: 'manual_setup_v2' },
};

const mountSection = async (inbox = INBOX) => {
  const wrapper = mount(WhatsappAppSecret, {
    props: { inbox },
    global: {
      stubs: {
        SettingsFieldSection: defineComponent({
          name: 'SettingsFieldSection',
          template: '<div><slot /></div>',
        }),
        'woot-input': defineComponent({
          name: 'WootInput',
          props: {
            modelValue: { type: String, default: '' },
            placeholder: { type: String, default: '' },
          },
          emits: ['update:modelValue'],
          setup:
            (props, { emit }) =>
            () =>
              h('input', {
                placeholder: props.placeholder,
                value: props.modelValue,
                onInput: event => emit('update:modelValue', event.target.value),
              }),
        }),
        NextButton: defineComponent({
          name: 'NextButton',
          props: { disabled: Boolean },
          emits: ['click'],
          setup:
            (props, { emit, slots }) =>
            () =>
              h(
                'button',
                {
                  class: 'save',
                  disabled: props.disabled,
                  onClick: () => emit('click'),
                },
                slots.default?.()
              ),
        }),
      },
    },
  });
  await nextTick();
  return wrapper;
};

describe('WhatsappAppSecret', () => {
  beforeEach(() => vi.clearAllMocks());

  // Without it the inbox's webhooks are taken unsigned, and only until the grace period ends.
  it('warns about an inbox without an app secret', async () => {
    const wrapper = await mountSection();

    expect(wrapper.find('[data-test-id="missing-app-secret"]').exists()).toBe(
      true
    );
  });

  it('does not warn once the inbox has one', async () => {
    const wrapper = await mountSection({
      ...INBOX,
      provider_config: { ...INBOX.provider_config, app_secret: 'secret' },
    });

    expect(wrapper.find('[data-test-id="missing-app-secret"]').exists()).toBe(
      false
    );
  });

  // provider_config is replaced wholesale by the inbox API, so the rest of it has to go along.
  it('saves the secret together with the rest of the provider config', async () => {
    const wrapper = await mountSection();

    await wrapper.find(SECRET_INPUT).setValue('  new-secret ');
    await wrapper.find('button.save').trigger('click');
    await flushPromises();

    expect(mockDispatch).toHaveBeenCalledWith('inboxes/updateInbox', {
      id: 7,
      formData: false,
      channel: {
        provider_config: {
          api_key: 'token',
          source: 'manual_setup_v2',
          app_secret: 'new-secret',
        },
      },
    });
    expect(mockAlert).toHaveBeenCalledWith(
      'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_APP_SECRET.SUCCESS'
    );
  });

  it('says what to check when the secret is refused', async () => {
    mockDispatch.mockRejectedValueOnce(new Error('Invalid Credentials'));
    const wrapper = await mountSection();

    await wrapper.find(SECRET_INPUT).setValue('wrong');
    await wrapper.find('button.save').trigger('click');
    await flushPromises();

    expect(mockAlert).toHaveBeenCalledWith(
      'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_APP_SECRET.ERROR'
    );
  });
});
