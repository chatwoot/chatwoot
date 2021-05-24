import { mount } from '@vue/test-utils';
import SidemenuIcon from '../SidemenuIcon';

describe('SidemenuIcon', () => {
  test('matches snapshot', () => {
    const wrapper = mount(SidemenuIcon);
    expect(wrapper.vm).toBeTruthy();
    expect(wrapper.element).toMatchSnapshot();
  });
});
