import { mount } from '@vue/test-utils';
import MessageReactions from '../MessageReactions.vue';

const mountComponent = reactions =>
  mount(MessageReactions, {
    props: { reactions },
  });

describe('MessageReactions', () => {
  it('renders active emoji and hides removed reactions', () => {
    const wrapper = mountComponent([
      { id: 1, emoji: '👍', status: 'active' },
      { id: 2, emoji: '👎', status: 'removed' },
    ]);

    expect(wrapper.text()).toContain('👍');
    expect(wrapper.text()).not.toContain('👎');
    expect(wrapper.findAll('[data-test-id="message-reaction"]')).toHaveLength(
      1
    );
  });

  it('falls back to camelCase and snake_case reaction type values', () => {
    const wrapper = mountComponent([
      { id: 1, reactionType: '🔥', status: 'active' },
      { id: 2, reaction_type: '❤️', status: 'active' },
    ]);

    expect(wrapper.text()).toContain('🔥');
    expect(wrapper.text()).toContain('❤️');
  });

  it('does not render outgoing controls', () => {
    const wrapper = mountComponent([{ id: 1, emoji: '👍', status: 'active' }]);

    expect(wrapper.find('button').exists()).toBe(false);
  });
});
