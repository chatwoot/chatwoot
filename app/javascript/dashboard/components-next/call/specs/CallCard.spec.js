import { mount } from '@vue/test-utils';
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
      showMute: true,
      ...props,
    },
    global: { stubs: { Avatar: true, Icon: true } },
  });

const muteButton = wrapper =>
  wrapper
    .findAll('button')
    .find(button =>
      ['i-ph-microphone-bold', 'i-ph-microphone-slash-bold'].includes(
        button.attributes('icon')
      )
    );

describe('CallCard mute controls', () => {
  it('offers mute on a live Twilio call and emits toggleMute', async () => {
    const wrapper = mountCard();

    expect(wrapper.text()).toContain('Call in progress');
    expect(muteButton(wrapper).attributes('icon')).toBe('i-ph-microphone-bold');

    await muteButton(wrapper).trigger('click');

    expect(wrapper.emitted('toggleMute')).toHaveLength(1);
  });

  it('shows a held Twilio call as on hold and muted', () => {
    const wrapper = mountCard({ onHold: true }, { isMuted: true });

    expect(wrapper.text()).toContain('On hold');
    expect(wrapper.text()).not.toContain('Call in progress');
    expect(muteButton(wrapper).attributes('icon')).toBe(
      'i-ph-microphone-slash-bold'
    );
  });

  it('has no mute control while an outbound Twilio call still rings the contact', () => {
    const wrapper = mountCard({ status: 'ringing' });

    expect(muteButton(wrapper)).toBeUndefined();
  });

  it('offers mute on a WhatsApp call without showing a hold', () => {
    const wrapper = mountCard({ provider: 'whatsapp', status: 'ringing' });

    expect(muteButton(wrapper)).toBeDefined();
    expect(wrapper.text()).not.toContain('On hold');
  });
});
