import { mount } from '@vue/test-utils';
import { VOICE_CALL_DIRECTION } from 'dashboard/components-next/message/constants';
import { withFullI18n } from 'test-i18n';
import CallCard from '../CallCard.vue';

withFullI18n();

const callInfo = {
  contactName: 'Jane',
  phoneNumber: '+15550001111',
  location: 'Support',
  hasLocation: false,
  countryFlag: '',
  avatar: '',
};

const mountCard = (call, props = {}) =>
  mount(CallCard, {
    props: {
      call: {
        callSid: 'CA1',
        provider: 'twilio',
        conversationId: 12,
        status: 'in-progress',
        ...call,
      },
      callInfo,
      state: 'ongoing',
      duration: '00:10',
      showCallControls: true,
      ...props,
    },
    global: { stubs: { Avatar: true, Icon: true } },
  });

const muteButton = wrapper =>
  wrapper.find('[data-test-id="voice-call-mute-toggle"]');
const holdButton = wrapper =>
  wrapper.find('[data-test-id="voice-call-hold-toggle"]');

describe('CallCard mute and hold controls', () => {
  it('offers separate mute and hold on a live Twilio call', async () => {
    const wrapper = mountCard();

    expect(wrapper.text()).toContain('Call in progress');
    expect(muteButton(wrapper).attributes('icon')).toBe('i-ph-microphone-bold');
    expect(holdButton(wrapper).attributes('icon')).toBe('i-ph-pause-bold');

    await muteButton(wrapper).trigger('click');
    await holdButton(wrapper).trigger('click');

    expect(wrapper.emitted('toggleMute')).toHaveLength(1);
    expect(wrapper.emitted('toggleHold')).toHaveLength(1);
  });

  it('shows a muted call as muted but still in progress', () => {
    const wrapper = mountCard({}, { isMuted: true });

    expect(wrapper.text()).toContain('Call in progress');
    expect(muteButton(wrapper).attributes('icon')).toBe(
      'i-ph-microphone-slash-bold'
    );
    expect(holdButton(wrapper).attributes('icon')).toBe('i-ph-pause-bold');
  });

  it('shows a held call as on hold with resume and the mute disabled', async () => {
    const wrapper = mountCard({ onHold: true });

    expect(wrapper.text()).toContain('On hold');
    expect(wrapper.text()).not.toContain('Call in progress');
    expect(holdButton(wrapper).attributes('icon')).toBe('i-ph-play-bold');
    expect(muteButton(wrapper).attributes('disabled')).toBeDefined();

    await holdButton(wrapper).trigger('click');

    expect(wrapper.emitted('toggleHold')).toHaveLength(1);
  });

  it('has no mute or hold while an outbound Twilio call still rings the contact', () => {
    const wrapper = mountCard({ status: 'ringing' });

    expect(muteButton(wrapper).exists()).toBe(false);
    expect(holdButton(wrapper).exists()).toBe(false);
  });

  it('offers mute and hold on a connected WhatsApp call', () => {
    const wrapper = mountCard({ provider: 'whatsapp', status: 'ringing' });

    expect(muteButton(wrapper).exists()).toBe(true);
    expect(holdButton(wrapper).exists()).toBe(true);
    expect(wrapper.text()).toContain('Call in progress');
  });

  it('shows a held WhatsApp call as on hold', () => {
    const wrapper = mountCard({ provider: 'whatsapp', onHold: true });

    expect(wrapper.text()).toContain('On hold');
    expect(holdButton(wrapper).attributes('icon')).toBe('i-ph-play-bold');
  });
});

const keypadCallInfo = {
  contactName: 'Apartment intercom',
  phoneNumber: '+16045550198',
  location: 'Vancouver, Canada',
  countryFlag: '',
  hasLocation: false,
  avatar: '',
};

const mountKeypadCard = (props = {}) =>
  mount(CallCard, {
    props: {
      call: { callSid: 'CA123', conversationId: 42, provider: 'twilio' },
      callInfo: keypadCallInfo,
      state: VOICE_CALL_DIRECTION.ONGOING,
      showKeypad: true,
      ...props,
    },
    global: {
      stubs: { Avatar: true, Icon: true },
    },
  });

describe('CallCard keypad', () => {
  it('starts collapsed and toggles the inline keypad', async () => {
    const wrapper = mountKeypadCard();
    const toggle = wrapper.find('[data-test-id="voice-call-keypad-toggle"]');

    expect(toggle.exists()).toBe(true);
    expect(toggle.attributes('aria-controls')).toBe('voice-call-keypad');
    expect(toggle.attributes('aria-expanded')).toBe('false');
    expect(toggle.attributes('aria-label')).toBe('Show keypad');
    expect(wrapper.find('#voice-call-keypad').exists()).toBe(false);

    await toggle.trigger('click');

    expect(toggle.attributes('aria-expanded')).toBe('true');
    expect(toggle.attributes('aria-label')).toBe('Hide keypad');
    expect(wrapper.find('#voice-call-keypad').exists()).toBe(true);
  });

  it('forwards clicked digits', async () => {
    const wrapper = mountKeypadCard();
    await wrapper
      .find('[data-test-id="voice-call-keypad-toggle"]')
      .trigger('click');
    await wrapper.find('[data-digit="9"]').trigger('click');

    expect(wrapper.emitted('sendDigit')).toEqual([['9']]);
  });

  it('hides and resets the keypad when availability becomes false', async () => {
    const wrapper = mountKeypadCard();
    await wrapper
      .find('[data-test-id="voice-call-keypad-toggle"]')
      .trigger('click');

    await wrapper.setProps({ showKeypad: false });
    expect(
      wrapper.find('[data-test-id="voice-call-keypad-toggle"]').exists()
    ).toBe(false);

    await wrapper.setProps({ showKeypad: true });
    expect(wrapper.find('#voice-call-keypad').exists()).toBe(false);
  });

  it('resets the keypad when the call changes', async () => {
    const wrapper = mountKeypadCard();
    await wrapper
      .find('[data-test-id="voice-call-keypad-toggle"]')
      .trigger('click');

    await wrapper.setProps({
      call: { callSid: 'CA456', conversationId: 42, provider: 'twilio' },
    });

    expect(wrapper.find('#voice-call-keypad').exists()).toBe(false);
  });

  it('does not expose the keypad outside an ongoing call', () => {
    const wrapper = mountKeypadCard({ state: VOICE_CALL_DIRECTION.INCOMING });

    expect(
      wrapper.find('[data-test-id="voice-call-keypad-toggle"]').exists()
    ).toBe(false);
  });
});
