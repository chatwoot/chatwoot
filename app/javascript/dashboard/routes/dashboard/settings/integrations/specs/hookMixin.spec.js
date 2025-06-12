import { shallowMount } from '@vue/test-utils';
import hookMixin from '../hookMixin';

describe('hookMixin', () => {
  const Component = {
    render() {},
    mixins: [hookMixin],
    data() {
      return {
        integration: {
          hook_type: 'inbox',
          hooks: [{ id: 1, properties: {} }],
        },
      };
    },
  };
  const wrapper = shallowMount(Component);

  it('#isHookTypeInbox returns correct value', () => {
    expect(wrapper.vm.isHookTypeInbox).toBe(true);
  });

  it('#hasConnectedHooks returns correct value', () => {
    expect(wrapper.vm.hasConnectedHooks).toBe(true);
  });
});
