import { mount, flushPromises } from '@vue/test-utils';
import CallBusinessHoursSettings from '../CallBusinessHoursSettings.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';

const { dispatch, alert } = vi.hoisted(() => ({
  dispatch: vi.fn(),
  alert: vi.fn(),
}));

vi.mock('vuex', async importOriginal => ({
  ...(await importOriginal()),
  useStore: () => ({ dispatch }),
}));
vi.mock('dashboard/composables', () => ({ useAlert: alert }));
const inbox = {
  id: 387,
  working_hours_enabled: true,
  business_hours_calls_enabled: true,
  out_of_hours_call_message: 'Call again tomorrow.',
  out_of_hours_call_audio_url: '/announcement.mp3',
};

const mountComponent = (overrides, stubs = {}) =>
  mount(CallBusinessHoursSettings, {
    props: { inbox: { ...inbox, ...overrides } },
    global: {
      stubs: {
        TextArea: true,
        Spinner: true,
        Icon: true,
        ...stubs,
        SettingsToggleSection: {
          props: ['modelValue', 'header', 'description'],
          template: '<section><slot name="editor" /></section>',
        },
      },
    },
  });

describe('CallBusinessHoursSettings', () => {
  beforeEach(() => vi.clearAllMocks());

  it('associates the announcement label with an inbox-specific textarea', () => {
    const wrapper = mountComponent({}, { TextArea: false });
    const textarea = wrapper.find('textarea');

    expect(textarea.attributes('id')).toBe('out-of-hours-call-message-387');
    expect(wrapper.find('label').attributes('for')).toBe(
      textarea.attributes('id')
    );
  });

  it('keeps playback of the saved announcement while editing', async () => {
    const wrapper = mountComponent();
    expect(wrapper.find('audio').attributes('src')).toBe('/announcement.mp3');

    wrapper
      .findComponent(TextArea)
      .vm.$emit('update:modelValue', 'New announcement');
    await wrapper.vm.$nextTick();

    expect(wrapper.find('audio').attributes('src')).toBe('/announcement.mp3');
  });

  it('saves edited text with one button and disables editing until saving completes', async () => {
    let finish;
    dispatch.mockReturnValue(
      new Promise(resolve => {
        finish = resolve;
      })
    );
    const wrapper = mountComponent();
    wrapper
      .findComponent(TextArea)
      .vm.$emit('update:modelValue', ' Updated announcement ');
    await wrapper.vm.$nextTick();
    wrapper.findComponent(NextButton).vm.$emit('click');
    await wrapper.vm.$nextTick();

    expect(dispatch).toHaveBeenCalledWith('inboxes/updateCallBusinessHours', {
      id: 387,
      enabled: true,
      message: 'Updated announcement',
    });
    expect(wrapper.findComponent(TextArea).props('disabled')).toBe(true);
    expect(
      wrapper.findComponent(NextButton).find('button').element.disabled
    ).toBe(true);
    finish();
    await flushPromises();
  });

  it('preserves unsaved text when an unrelated inbox refresh arrives', async () => {
    const wrapper = mountComponent();
    wrapper
      .findComponent(TextArea)
      .vm.$emit('update:modelValue', 'Unsaved announcement');
    await wrapper.vm.$nextTick();
    await wrapper.setProps({ inbox: { ...inbox } });

    expect(wrapper.findComponent(TextArea).props('modelValue')).toBe(
      'Unsaved announcement'
    );
    expect(dispatch).not.toHaveBeenCalled();
  });

  it('allows saving unchanged text when audio is missing and disables saving once audio exists', async () => {
    dispatch.mockResolvedValue();
    const wrapper = mountComponent({ out_of_hours_call_audio_url: null });
    const button = wrapper.findComponent(NextButton).find('button');

    expect(button.element.disabled).toBe(false);
    await button.trigger('click');
    await flushPromises();

    expect(dispatch).toHaveBeenCalledWith('inboxes/updateCallBusinessHours', {
      id: 387,
      enabled: true,
      message: inbox.out_of_hours_call_message,
    });

    await wrapper.setProps({ inbox: { ...inbox } });

    expect(button.element.disabled).toBe(true);
  });

  it('restores the saved toggle after a failed update', async () => {
    dispatch.mockRejectedValue(new Error('Update failed'));
    const wrapper = mountComponent();
    wrapper
      .findComponent(SettingsToggleSection)
      .vm.$emit('update:modelValue', false);
    await flushPromises();

    expect(
      wrapper.findComponent(SettingsToggleSection).props('modelValue')
    ).toBe(true);
    expect(alert).toHaveBeenCalled();
  });
});
