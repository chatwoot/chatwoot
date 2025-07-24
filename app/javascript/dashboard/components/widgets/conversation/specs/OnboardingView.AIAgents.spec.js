import { describe, it, expect, vi } from 'vitest';
import { mount } from '@vue/test-utils';
import AddAIAgentView from '../OnboardingView.AddAIAgent.vue';

vi.mock('../../../../routes/dashboard/settings/agentBots/Index.vue', () => ({
  default: {
    name: 'Index',
    template: '<div class="mock-index">Index Component</div>',
  },
}));

describe('OnboardingView.AddAIAgent.vue', () => {
  it('should render the component', () => {
    const wrapper = mount(AddAIAgentView);
    expect(wrapper.html()).toMatchSnapshot();
  });

  it('render the index when current step is equal to stepNumber', () => {
    const wrapper = mount(AddAIAgentView, {
      props: {
        currentStep: 1,
        stepNumber: 1,
      },
    });
    expect(wrapper.find('.mock-index').exists()).toBe(true);
  });

  it('should not render when the step is not the current step', () => {
    const wrapper = mount(AddAIAgentView, {
      props: {
        currentStep: 1,
        stepNumber: 2,
      },
    });
    expect(wrapper.find('.mock-index').exists()).toBe(false);
  });
});
