import { mount } from '@vue/test-utils';
import CallKeypad from '../CallKeypad.vue';

const mountKeypad = () => mount(CallKeypad);

describe('CallKeypad', () => {
  it('renders the twelve telephone keys in standard order', () => {
    const wrapper = mountKeypad();
    const keys = wrapper.findAll('[data-test-id="voice-call-keypad-key"]');

    expect(keys).toHaveLength(12);
    expect(keys.map(key => key.attributes('data-digit'))).toEqual([
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '*',
      '0',
      '#',
    ]);
    keys.forEach(key => expect(key.element.tagName).toBe('BUTTON'));
  });

  it('emits one digit when a visible key is clicked', async () => {
    const wrapper = mountKeypad();

    await wrapper.find('[data-digit="9"]').trigger('click');
    await wrapper.find('[data-digit="#"]').trigger('click');

    expect(wrapper.emitted('digit')).toEqual([['9'], ['#']]);
  });

  it('provides accessible labels without changing button behavior', () => {
    const wrapper = mountKeypad();
    const keypad = wrapper.find('#voice-call-keypad');
    const keys = wrapper.findAll('[data-test-id="voice-call-keypad-key"]');

    expect(keypad.attributes('role')).toBe('group');
    expect(keypad.attributes('aria-label')).toBe('Call keypad');
    expect(wrapper.find('[data-digit="*"]').attributes('aria-label')).toBe(
      'Star'
    );
    expect(wrapper.find('[data-digit="#"]').attributes('aria-label')).toBe(
      'Pound'
    );
    keys.forEach(key => expect(key.attributes('type')).toBe('button'));
  });

  it('does not emit digits from keyboard events', async () => {
    const wrapper = mountKeypad();

    await wrapper.trigger('keydown', { key: '9' });

    expect(wrapper.emitted('digit')).toBeUndefined();
  });
});
