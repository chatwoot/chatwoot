import { mount } from '@vue/test-utils';
import { VOICE_CALL_DIRECTION } from 'dashboard/components-next/message/constants';
import CallCard from '../CallCard.vue';

const callInfo = {
  contactName: 'Apartment intercom',
  phoneNumber: '+16045550198',
  location: 'Vancouver, Canada',
  countryFlag: '',
  hasLocation: false,
  avatar: '',
};

const mountCard = (props = {}) =>
  mount(CallCard, {
    props: {
      call: { callSid: 'CA123', conversationId: 42, provider: 'twilio' },
      callInfo,
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
    const wrapper = mountCard();
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
    const wrapper = mountCard();
    await wrapper
      .find('[data-test-id="voice-call-keypad-toggle"]')
      .trigger('click');
    await wrapper.find('[data-digit="9"]').trigger('click');

    expect(wrapper.emitted('sendDigit')).toEqual([['9']]);
  });

  it('hides and resets the keypad when availability becomes false', async () => {
    const wrapper = mountCard();
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
    const wrapper = mountCard();
    await wrapper
      .find('[data-test-id="voice-call-keypad-toggle"]')
      .trigger('click');

    await wrapper.setProps({
      call: { callSid: 'CA456', conversationId: 42, provider: 'twilio' },
    });

    expect(wrapper.find('#voice-call-keypad').exists()).toBe(false);
  });

  it('does not expose the keypad outside an ongoing call', () => {
    const wrapper = mountCard({ state: VOICE_CALL_DIRECTION.INCOMING });

    expect(
      wrapper.find('[data-test-id="voice-call-keypad-toggle"]').exists()
    ).toBe(false);
  });
});
