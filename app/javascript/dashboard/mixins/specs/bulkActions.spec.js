import { mount } from '@vue/test-utils';
import bulkActionsMixin from '../bulkActionsMixin';
describe('bulkActionsMixin', () => {
  it('returns the prop and computed values for triangle position:', async () => {
    const Component = {
      render() {},
      title: 'MyComponent',
      mixins: [bulkActionsMixin],
    };
    const wrapper = mount(Component);
    await wrapper.setProps({
      trianglePosition: '10',
    });
    expect(wrapper.props().trianglePosition).toEqual('10');
    expect(wrapper.vm.cssVars).toEqual({
      '--triangle-position': '10rem',
    });
  });
});
