import { shallowMount } from '@vue/test-utils';
import AgentCapacityPolicyCard from './AgentCapacityPolicyCard.vue';
import CardPopover from '../components/CardPopover.vue';

describe('AgentCapacityPolicyCard', () => {
  it('shows avatars from the agent response in the assigned users popover', () => {
    const wrapper = shallowMount(AgentCapacityPolicyCard, {
      global: {
        stubs: {
          CardLayout: { template: '<div><slot /></div>' },
        },
      },
      props: {
        id: 1,
        users: [
          {
            id: 2,
            name: 'Agent',
            email: 'agent@example.com',
            thumbnail: 'https://example.com/avatar.png',
          },
        ],
      },
    });

    expect(wrapper.findComponent(CardPopover).props('items')[0].avatarUrl).toBe(
      'https://example.com/avatar.png'
    );
  });
});
