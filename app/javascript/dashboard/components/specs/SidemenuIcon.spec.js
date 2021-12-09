import { shallowMount } from '@vue/test-utils';
import SidemenuIcon from '../SidemenuIcon';

describe('SidemenuIcon', () => {
  test('matches snapshot', () => {
    const wrapper = shallowMount(SidemenuIcon);
    expect(wrapper.vm).toBeTruthy();
    expect(wrapper.element).toMatchSnapshot();
  });
});
