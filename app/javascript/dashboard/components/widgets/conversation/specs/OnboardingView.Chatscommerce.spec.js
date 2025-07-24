import { mount } from '@vue/test-utils';
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { nextTick, computed, ref } from 'vue';
import OnboardingViewChatscommerce from '../OnboardingView.Chatscommerce.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: (key, params) => {
      if (key === 'ONBOARDING.GREETING_MORNING' && params) {
        return `Good morning ${params.name}! Welcome to ${params.installationName}`;
      }
      if (key === 'ONBOARDING.DESCRIPTION' && params) {
        return `Let's set up ${params.installationName} for you`;
      }
      return key;
    },
  }),
}));

let mockAgents = ref([{ id: 1 }]);
let mockInboxes = ref([{ has_members: true }]);
let mockBots = ref([{ id: 1 }]);

vi.mock('dashboard/composables/store', () => {
  const mockUser = ref({ name: 'Test User' });
  const mockGlobalConfig = ref({ installationName: 'Test App' });
  const mockDispatch = vi.fn().mockResolvedValue();

  return {
    useStore: () => ({
      dispatch: mockDispatch,
    }),
    useStoreGetters: () => ({
      getCurrentUser: computed(() => mockUser.value),
      'globalConfig/get': computed(() => mockGlobalConfig.value),
    }),
    useMapGetter: getterName => {
      const data = {
        'agents/getAgents': mockAgents,
        'inboxes/getInboxes': mockInboxes,
        'agentBots/getBots': mockBots,
      };
      return computed(() => data[getterName] || []);
    },
  };
});

vi.mock('dashboard/composables/useBranding', () => ({
  useBranding: () => ({
    isACustomBrandedInstance: ref(false),
  }),
}));

// Mock child components as simple text
vi.mock('../../../../../shared/components/Button.vue', () => ({
  default: {
    name: 'Button',
    props: ['disabled'],
    template:
      '<button :disabled="disabled" class="mock-button"><slot /></button>',
  },
}));

vi.mock('../../../../../shared/components/StepCircleFlow.vue', () => ({
  default: {
    name: 'StepCircleFlow',
    template:
      '<div class="mock-step-circle-flow">StepCircleFlowComponent</div>',
  },
}));

vi.mock('../OnboardingView.AddAgent.vue', () => ({
  default: {
    name: 'OnboardingViewAddAgent',
    template: '<div class="mock-add-agent">AddAgentComponent</div>',
  },
}));

vi.mock('../OnboardingView.AddChannel.vue', () => ({
  default: {
    name: 'OnboardingViewAddChannel',
    template: '<div class="mock-add-channel">AddChannelComponent</div>',
  },
}));

vi.mock('../OnboardingView.AddAIAgent.vue', () => ({
  default: {
    name: 'OnboardingViewAddAIAgent',
    template: '<div class="mock-add-ai-agent">AddAIAgentComponent</div>',
  },
}));

vi.mock(
  'dashboard/components/widgets/conversation/CustomBrandPolicyWrapper.vue',
  () => ({
    default: { template: '<div>CustomBrandPolicyWrapper</div>' },
  })
);

vi.mock('dashboard/components/CustomBrandPolicyWrapper.vue', () => ({
  default: { template: '<div>CustomBrandPolicyWrapper</div>' },
}));

beforeAll(() => {
  window.chatwootConfig = {
    chatscommerceApiUrl: 'https://mocked-api-url.com',
  };
});
afterAll(() => {
  delete window.chatwootConfig;
});

describe('OnboardingViewChatscommerce', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = mount(OnboardingViewChatscommerce, {
      global: {
        mocks: {
          $t: (key, params) => {
            if (key === 'ONBOARDING.DESCRIPTION') {
              return `Let's set up ${params.installationName} for you`;
            }
            if (key === 'ONBOARDING.GREETING_MORNING') return 'Good morning!';
            if (key === 'ONBOARDING.BUTTON.NEXT') return 'Next';
            if (key === 'ONBOARDING.BUTTON.PREVIOUS') return 'Previous';
            if (key === 'ONBOARDING.BUTTON.FINISH') return 'Finish';
            return key;
          },
        },
      },
    });
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.unmount();
    }
    vi.restoreAllMocks();
  });

  it('renders none when is loading', () => {
    wrapper.vm.isLoading = true;
    expect(wrapper.html()).toMatchInlineSnapshot(`
      "<div>
        <!--v-if-->
      </div>"
    `);
  });

  it('renders greeting message', async () => {
    wrapper.vm.isLoading = false;
    await nextTick();
    expect(wrapper.text()).toContain(
      'Good morning Test User! Welcome to Test App'
    );
  });

  it('renders description message', async () => {
    wrapper.vm.isLoading = false;
    await nextTick();
    expect(wrapper.text()).toContain("Let's set up Test App for you");
  });

  it('renders the correct component based on the current step', async () => {
    wrapper.vm.isLoading = false;
    wrapper.vm.currentStep = 1;
    await nextTick();
    expect(wrapper.find('.mock-add-agent').exists()).toBe(true);
    expect(wrapper.find('.mock-add-channel').exists()).toBe(false);
    expect(wrapper.find('.mock-add-ai-agent').exists()).toBe(false);

    wrapper.vm.currentStep = 2;
    await nextTick();
    expect(wrapper.find('.mock-add-agent').exists()).toBe(false);
    expect(wrapper.find('.mock-add-channel').exists()).toBe(true);
    expect(wrapper.find('.mock-add-ai-agent').exists()).toBe(false);

    wrapper.vm.currentStep = 3;
    await nextTick();
    expect(wrapper.find('.mock-add-agent').exists()).toBe(false);
    expect(wrapper.find('.mock-add-channel').exists()).toBe(false);
    expect(wrapper.find('.mock-add-ai-agent').exists()).toBe(true);
  });

  it('should move to the next step when the next button is clicked', async () => {
    wrapper.vm.isLoading = false;
    wrapper.vm.currentStep = 2;
    wrapper.vm.stepCompletionStatus = {
      1: true,
      2: true,
      3: false,
    };
    await nextTick();

    const nextButton = wrapper
      .findAll('.mock-button')
      .find(button => button.text() === 'Next');

    nextButton.trigger('click');
    await nextTick();
    expect(wrapper.vm.currentStep).toBe(3);
  });

  it('should move to the previous step when the previous button is clicked', async () => {
    wrapper.vm.isLoading = false;
    wrapper.vm.currentStep = 3;
    await nextTick();

    const previousButton = wrapper
      .findAll('.mock-button')
      .find(button => button.text() === 'Previous');

    previousButton.trigger('click');
    await nextTick();
    expect(wrapper.vm.currentStep).toBe(2);
  });

  it('should render the finish button when the current step is the last step', async () => {
    wrapper.vm.isLoading = false;
    wrapper.vm.currentStep = 3;
    wrapper.vm.stepCompletionStatus = {
      1: true,
      2: true,
      3: false,
    };

    await nextTick();

    let finishButton = wrapper
      .findAll('.mock-button')
      .find(button => button.text() === 'Finish');
    await nextTick();
    expect(finishButton).toBeUndefined();

    wrapper.vm.stepCompletionStatus = {
      1: true,
      2: true,
      3: true,
    };
    await nextTick();
    finishButton = wrapper
      .findAll('.mock-button')
      .find(button => button.text() === 'Finish');
    expect(finishButton.exists()).toBe(true);
  });
});
