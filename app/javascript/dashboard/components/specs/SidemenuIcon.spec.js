import { shallowMount } from '@vue/test-utils';
import SidemenuIcon from '../SidemenuIcon.vue';

describe('SidemenuIcon', () => {
  test('matches snapshot', () => {
    const wrapper = shallowMount(SidemenuIcon, {
      stubs: { WootButton: { template: '<button><slot /></button>' } },
    });
    expect(wrapper.vm).toBeTruthy();
    expect(wrapper.element).toMatchSnapshot();
  });
});
