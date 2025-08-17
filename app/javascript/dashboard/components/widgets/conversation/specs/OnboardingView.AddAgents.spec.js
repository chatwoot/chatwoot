import { describe, it, expect } from 'vitest';
import { mount } from '@vue/test-utils';
import AddAgentView from '../OnboardingView.AddAgent.vue';
import { vi } from 'vitest';

// Mock the Index component
vi.mock('../../../../routes/dashboard/settings/agents/Index.vue', () => ({
  default: {
    name: 'Index',
    template: '<div class="mock-index">Index Component</div>',
  },
}));

describe('OnboardingView.AddAgent.vue', () => {
  it('should render the component', () => {
    const wrapper = mount(AddAgentView);
    expect(wrapper.html()).toMatchSnapshot();
  });

  it('render the index when current step is equal to stepNumber', () => {
    const wrapper = mount(AddAgentView, {
      props: {
        currentStep: 1,
        stepNumber: 1,
      },
    });
    expect(wrapper.find('.mock-index').exists()).toBe(true);
  });

  it('should not render when the step is not the current step', () => {
    const wrapper = mount(AddAgentView, {
      props: {
        currentStep: 1,
        stepNumber: 2,
      },
    });
    expect(wrapper.find('.mock-index').exists()).toBe(false);
  });
});
