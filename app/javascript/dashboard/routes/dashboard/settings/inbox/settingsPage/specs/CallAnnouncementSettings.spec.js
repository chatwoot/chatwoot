import { mount, flushPromises } from '@vue/test-utils';
import CallAnnouncementSettings from '../CallAnnouncementSettings.vue';
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

const inbox = { id: 387 };
const props = {
  inbox,
  kind: 'out_of_hours',
  i18nKey: 'BUSINESS_HOURS',
  enabled: true,
  message: 'Call again tomorrow.',
  audioUrl: '/announcement.mp3',
};

const mountComponent = (overrides, stubs = {}) =>
  mount(CallAnnouncementSettings, {
    props: { ...props, ...overrides },
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

describe('CallAnnouncementSettings', () => {
  beforeEach(() => vi.clearAllMocks());

  it('opens the message under its checkbox and saves when it is unchecked', async () => {
    dispatch.mockResolvedValue();
    const wrapper = mountComponent({ checkbox: true }, { TextArea: false });
    const checkbox = wrapper.find('input[type="checkbox"]');

    expect(checkbox.element.checked).toBe(true);
    expect(wrapper.find('textarea').attributes('id')).toBe(
      'call-announcement-out_of_hours-387'
    );

    await checkbox.setValue(false);
    await flushPromises();

    expect(wrapper.find('textarea').exists()).toBe(false);
    expect(dispatch).toHaveBeenCalledWith('inboxes/updateCallAnnouncement', {
      id: 387,
      kind: 'out_of_hours',
      enabled: false,
      message: 'Call again tomorrow.',
    });
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

  it('saves edited text for its kind and disables editing until saving completes', async () => {
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

    expect(dispatch).toHaveBeenCalledWith('inboxes/updateCallAnnouncement', {
      id: 387,
      kind: 'out_of_hours',
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

  it('turns a greeting on with its saved text under its own kind', async () => {
    dispatch.mockResolvedValue();
    const wrapper = mountComponent({
      kind: 'greeting',
      i18nKey: 'GREETING',
      enabled: false,
      message: 'Welcome',
      audioUrl: null,
    });

    wrapper
      .findComponent(SettingsToggleSection)
      .vm.$emit('update:modelValue', true);
    await flushPromises();

    expect(dispatch).toHaveBeenCalledWith('inboxes/updateCallAnnouncement', {
      id: 387,
      kind: 'greeting',
      enabled: true,
      message: 'Welcome',
    });
  });

  it('saves the ring time with a no-answer announcement', async () => {
    dispatch.mockResolvedValue();
    const wrapper = mountComponent(
      {
        kind: 'unanswered',
        i18nKey: 'UNANSWERED',
        message: 'Nobody is available.',
        audioUrl: null,
        timeoutSeconds: 60,
      },
      { NextInput: false }
    );

    await wrapper.find('input[type="number"]').setValue('45');
    wrapper.findComponent(NextButton).vm.$emit('click');
    await flushPromises();

    expect(dispatch).toHaveBeenCalledWith('inboxes/updateCallAnnouncement', {
      id: 387,
      kind: 'unanswered',
      enabled: true,
      message: 'Nobody is available.',
      timeoutSeconds: 45,
    });
  });

  it('sends no ring time for announcements without one', async () => {
    dispatch.mockResolvedValue();
    const wrapper = mountComponent();
    expect(wrapper.find('input[type="number"]').exists()).toBe(false);

    wrapper
      .findComponent(SettingsToggleSection)
      .vm.$emit('update:modelValue', false);
    await flushPromises();

    expect(dispatch).toHaveBeenCalledWith('inboxes/updateCallAnnouncement', {
      id: 387,
      kind: 'out_of_hours',
      enabled: false,
      message: 'Call again tomorrow.',
      timeoutSeconds: undefined,
    });
  });

  it('shows no Captain audio for a text-only announcement', () => {
    const wrapper = mountComponent({
      kind: 'greeting',
      i18nKey: 'GREETING',
      message: 'Welcome',
      audioUrl: null,
    });

    expect(wrapper.text()).not.toContain('Captain');
    expect(wrapper.find('audio').exists()).toBe(false);
    expect(
      wrapper.findComponent(NextButton).find('button').element.disabled
    ).toBe(true);
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

  it('allows saving unchanged text while its audio is missing', async () => {
    dispatch.mockResolvedValue();
    const wrapper = mountComponent({ audioUrl: '' });
    const button = wrapper.findComponent(NextButton).find('button');

    expect(button.element.disabled).toBe(false);
    await button.trigger('click');
    await flushPromises();

    expect(dispatch).toHaveBeenCalledWith('inboxes/updateCallAnnouncement', {
      id: 387,
      kind: 'out_of_hours',
      enabled: true,
      message: 'Call again tomorrow.',
    });

    await wrapper.setProps({ audioUrl: '/announcement.mp3' });

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
