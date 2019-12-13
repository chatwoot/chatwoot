import { mount } from '@vue/test-utils';
import Spinner from '../Spinner';

describe('Spinner', () => {
  test('matches snapshot', () => {
    const wrapper = mount(Spinner);
    expect(wrapper.isVueInstance()).toBeTruthy();
    expect(wrapper.element).toMatchSnapshot();
  });
});
