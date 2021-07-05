import { mount } from '@vue/test-utils';
import DateSeparator from '../DateSeparator';

describe('DateSeparator', () => {
  test('matches snapshot', () => {
    const wrapper = mount(DateSeparator, {
      propsData: {
        date: 'Nov 18, 2019',
      },
      mocks: {
        $t: () => {},
      },
    });
    expect(wrapper.vm).toBeTruthy();
    expect(wrapper.element).toMatchSnapshot();
  });
});
