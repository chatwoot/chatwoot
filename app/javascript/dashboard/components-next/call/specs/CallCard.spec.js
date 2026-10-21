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

const mountCard = call =>
  mount(CallCard, {
    props: {
      call: { callSid: 'CA1', provider: 'twilio', conversationId: 12, ...call },
      callInfo,
      state: 'ongoing',
      duration: '00:10',
      showMute: true,
    },
    global: { stubs: { Avatar: true, Icon: true } },
  });

const holdButton = wrapper =>
  wrapper
    .findAll('button')
    .find(button =>
      ['i-ph-pause-bold', 'i-ph-play-bold'].includes(button.attributes('icon'))
    );

describe('CallCard hold controls', () => {
  it('offers Hold on a live Twilio call and emits toggleHold', async () => {
    const wrapper = mountCard();

    expect(wrapper.text()).toContain('Call in progress');
    expect(holdButton(wrapper).attributes('icon')).toBe('i-ph-pause-bold');

    await holdButton(wrapper).trigger('click');

    expect(wrapper.emitted('toggleHold')).toHaveLength(1);
  });

  it('shows the call on hold with a Resume control', () => {
    const wrapper = mountCard({ onHold: true });

    expect(wrapper.text()).toContain('On hold');
    expect(wrapper.text()).not.toContain('Call in progress');
    expect(holdButton(wrapper).attributes('icon')).toBe('i-ph-play-bold');
  });

  it('has no hold control on a WhatsApp call', () => {
    const wrapper = mountCard({ provider: 'whatsapp' });

    expect(holdButton(wrapper)).toBeUndefined();
  });
});
