import { vi } from 'vitest';
import { describe, it, expect } from 'vitest';
import { mount } from '@vue/test-utils';
import AddChannelView from '../OnboardingView.AddChannel.vue';

// Mock dependencies
vi.mock('../../../../routes/dashboard/settings/inbox/ChannelList.vue', () => ({
  default: {
    name: 'ChannelList',
    template:
      '<div class="mock-channel-list" @click="$emit(\'onChannelItemClick\', \'whatsapp\')">ChannelList</div>',
  },
}));

vi.mock('../../../../routes/dashboard/settings/inbox/AddAgents.vue', () => ({
  default: {
    name: 'AddAgents',
    template: '<div class="mock-add-agents">AddAgents Component</div>',
  },
}));

vi.mock(
  '../../../../routes/dashboard/settings/inbox/channels/Whatsapp.vue',
  () => ({
    default: {
      name: 'Whatsapp',
      template: '<div class="mock-whatsapp">Whatsapp Component</div>',
    },
  })
);

vi.mock(
  '../../../../routes/dashboard/settings/inbox/channels/Instagram.vue',
  () => ({
    default: {
      name: 'Instagram',
      template: '<div class="mock-instagram">Instagram Component</div>',
    },
  })
);

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: key => key,
  }),
}));

vi.mock('dashboard/composables', () => ({
  useAlert: () => ({
    show: vi.fn(),
  }),
}));

let mockStores = [];

vi.mock('vuex', async () => {
  const actual = await vi.importActual('vuex');
  return {
    ...actual,
    useStore: () => ({
      getters: {
        'inboxes/getInboxes': mockStores,
      },
    }),
  };
});

describe('OnboardingView.AddChannel.vue', () => {
  let store;

  beforeEach(() => {
    store = {
      getters: {
        'inboxes/getInboxes': [],
      },
    };
  });

  it('does not render if currentStep !== stepNumber', () => {
    const wrapper = mount(AddChannelView, {
      props: {
        currentStep: 1,
        stepNumber: 2,
      },
    });
    expect(wrapper.html()).toMatchInlineSnapshot(`
        "<div>
          <!--v-if-->
        </div>"
      `);
  });

  it('shows ChannelList when no channel is selected and no imbox created', () => {
    const wrapper = mount(AddChannelView, {
      props: {
        currentStep: 1,
        stepNumber: 1,
      },
      global: {
        mocks: {
          $store: store,
        },
      },
    });
    expect(wrapper.find('.mock-channel-list').exists()).toBe(true);
  });

  it('renders selected channel component when one is selected and no inbox created', async () => {
    const wrapper = mount(AddChannelView, {
      props: {
        currentStep: 2,
        stepNumber: 2,
      },
      global: {
        mocks: {
          $store: store,
        },
      },
    });

    // Simulate channel item click
    await wrapper.find('.mock-channel-list').trigger('click');

    expect(wrapper.find('.mock-whatsapp').exists()).toBe(true);
  });

  it('should AddAgents when inbox already exists', async () => {
    mockStores = [
      {
        id: 123,
        channel_type: 'whatsapp',
      },
    ];
    const wrapper = mount(AddChannelView, {
      props: {
        currentStep: 1,
        stepNumber: 1,
      },
      global: {
        mocks: {
          $store: {
            getters: {
              'inboxes/getInboxes': mockStores,
            },
          },
        },
      },
    });

    // Set the channel step to 'success' to make channelFullySetup true
    await wrapper.vm.handleStepChanged('success');

    expect(wrapper.find('.mock-add-agents').exists()).toBe(true);
  });
});
