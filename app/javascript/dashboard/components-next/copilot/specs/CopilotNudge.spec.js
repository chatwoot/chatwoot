import { mount } from '@vue/test-utils';

import CopilotNudge from '../CopilotNudge.vue';

const mountComponent = show =>
  mount(CopilotNudge, {
    props: { show },
    slots: { default: '<button class="copilot-button">Copilot</button>' },
  });

describe('CopilotNudge', () => {
  it('marks the button with the brand dot until the person opens Copilot', () => {
    const wrapper = mountComponent(true);

    expect(wrapper.find('[data-test-id="copilot-dot"]').exists()).toBe(true);
    expect(wrapper.findAll('button').map(button => button.text())).toEqual([
      'Copilot',
    ]);
  });

  it('leaves only the button once the person has opened Copilot', () => {
    const wrapper = mountComponent(false);

    expect(wrapper.find('[data-test-id="copilot-dot"]').exists()).toBe(false);
  });
});
