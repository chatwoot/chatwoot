import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import AgentDetails from '../AgentDetails.vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import WootButton from 'dashboard/components/ui/WootButton.vue';

describe('AgentDetails', () => {
  const currentUser = {
    name: 'Neymar Junior',
    avatar_url: '',
    availability_status: 'online',
  };
  const currentRole = 'agent';
  let store = null;
  let agentDetails = null;

  const mockTooltipDirective = {
    mounted: (el, binding) => {
      // You can mock the behavior here if necessary
      el.setAttribute('data-tooltip', binding.value || '');
    },
  };

  beforeEach(() => {
    store = createStore({
      modules: {
        auth: {
          namespaced: false,
          getters: {
            getCurrentUser: () => currentUser,
            getCurrentRole: () => currentRole,
            getCurrentUserAvailability: () => currentUser.availability_status,
          },
        },
      },
    });

    agentDetails = shallowMount(AgentDetails, {
      global: {
        plugins: [store],
        components: {
          Thumbnail,
          WootButton,
        },
        directives: {
          tooltip: mockTooltipDirective, // Mocking the tooltip directive
        },
        stubs: { WootButton: { template: '<button><slot /></button>' } },
      },
    });
  });

  it('shows the correct agent status', () => {
    expect(agentDetails.findComponent(Thumbnail).vm.status).toBe('online');
  });

  it('agent thumbnail exists', () => {
    const thumbnailComponent = agentDetails.findComponent(Thumbnail);
    expect(thumbnailComponent.exists()).toBe(true);
  });
});
