import { mount } from '@vue/test-utils';
import Index from '../Index.vue';

vi.mock('dashboard/composables/useAdmin', () => ({
  useAdmin: () => ({
    isAdmin: { value: true },
  }),
}));

describe('ContextMenu/Index (Agent Search)', () => {
  const mountMenu = (
    props = {},
    agents = [
      {
        id: 1,
        name: 'Agent One',
        email: 'agent1@example.com',
        availability_status: 'online',
      },
      {
        id: 2,
        name: 'Agent Two',
        email: 'agent2@example.com',
        availability_status: 'offline',
      },
    ]
  ) =>
    mount(Index, {
      props: {
        chatId: 1,
        inboxId: 1,
        status: 'open',
        hasUnreadMessages: false,
        allowedOptions: ['agent'],
        ...props,
      },
      global: {
        mocks: {
          $t: key => key,
          $store: {
            getters: {
              'labels/getLabels': [],
              'inboxAssignableAgents/getAssignableAgents': () => agents,
              'inboxAssignableAgents/getUIFlags': { isFetching: false },
              getCurrentUser: {
                id: 1,
                accounts: [{ id: 1, availability_status: 'online' }],
              },
              getCurrentAccountId: 1,
              'teams/getTeams': [],
            },
            dispatch: vi.fn(),
          },
        },
      },
    });

  it('defines focusAgentSearchInput and handleGlobalKeyDown methods', () => {
    const wrapper = mountMenu();
    expect(typeof wrapper.vm.focusAgentSearchInput).toBe('function');
    expect(typeof wrapper.vm.handleGlobalKeyDown).toBe('function');
  });

  it('focuses the agent search input on focusAgentSearchInput call', async () => {
    const wrapper = mountMenu();
    const input = wrapper.find('input[type="search"]');
    expect(input.exists()).toBe(true);
    const focusSpy = vi.spyOn(input.element, 'focus');
    wrapper.vm.focusAgentSearchInput();
    await wrapper.vm.$nextTick();
    expect(focusSpy).toHaveBeenCalled();
  });

  it('filters assignable agents based on agentSearchQuery', async () => {
    const wrapper = mountMenu();
    expect(wrapper.vm.filteredAssignableAgents.length).toBe(3); // None + 2 agents

    wrapper.vm.agentSearchQuery = 'One';
    await wrapper.vm.$nextTick();
    expect(
      wrapper.vm.filteredAssignableAgents.some(a => a.name === 'Agent One')
    ).toBe(true);
    expect(
      wrapper.vm.filteredAssignableAgents.some(a => a.name === 'Agent Two')
    ).toBe(false);
  });

  it('handles global keydown and updates agentSearchQuery when agent submenu is hovered', () => {
    const wrapper = mountMenu();
    wrapper.vm.isAgentSubmenuHovered = true;
    const event = {
      key: 'a',
      ctrlKey: false,
      metaKey: false,
      altKey: false,
      preventDefault: vi.fn(),
      target: document.body,
    };
    wrapper.vm.handleGlobalKeyDown(event);
    expect(wrapper.vm.agentSearchQuery).toBe('a');
  });

  it('navigates agents with arrow keys and selects with Enter', async () => {
    const wrapper = mountMenu();
    expect(wrapper.vm.activeAgentIndex).toBe(0);

    wrapper.vm.moveActiveAgent(1);
    expect(wrapper.vm.activeAgentIndex).toBe(1);

    wrapper.vm.moveActiveAgent(-1);
    expect(wrapper.vm.activeAgentIndex).toBe(0);

    const assignSpy = vi.spyOn(wrapper.vm, 'assignSelectedAgent');
    wrapper.vm.selectActiveAgent();
    expect(assignSpy).toHaveBeenCalledWith(
      wrapper.vm.filteredAssignableAgents[0]
    );
  });

  it('resets activeAgentIndex to 0 when agentSearchQuery changes', async () => {
    const wrapper = mountMenu();
    wrapper.vm.moveActiveAgent(1);
    expect(wrapper.vm.activeAgentIndex).toBe(1);

    wrapper.vm.agentSearchQuery = 'Two';
    await wrapper.vm.$nextTick();
    expect(wrapper.vm.activeAgentIndex).toBe(0);
  });

  it('shows no agents found message when no agent matches the query', async () => {
    const wrapper = mountMenu();
    wrapper.vm.agentSearchQuery = 'NonExistentAgent';
    await wrapper.vm.$nextTick();
    expect(wrapper.vm.filteredAssignableAgents.length).toBe(0);
    const noAgentsText = wrapper.find('.text-n-slate-11');
    expect(noAgentsText.exists()).toBe(true);
  });
});
