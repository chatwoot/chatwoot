import { mount } from '@vue/test-utils';
import DateSeparator from '../DateSeparator';

describe('Spinner', () => {
  test('matches snapshot', () => {
    const wrapper = mount(DateSeparator, {
      propsData: {
        date: 'Nov 18, 2019',
      },
    });
    expect(wrapper.isVueInstance()).toBeTruthy();
    expect(wrapper.element).toMatchSnapshot();
  });
});
