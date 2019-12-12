import { mount } from '@vue/test-utils';
import SidemenuIcon from '../SidemenuIcon';

describe('SidemenuIcon', () => {
  test('matches snapshot', () => {
    const wrapper = mount(SidemenuIcon);
    expect(wrapper.isVueInstance()).toBeTruthy();
    expect(wrapper.element).toMatchSnapshot();
  });
});
