import { shallowMount } from '@vue/test-utils';
import contentTypeMixin from '../contentTypeMixin';

describe('contentTypeMixin', () => {
  it('returns true if contentType is incoming_email', () => {
    const Component = {
      render() {},
      mixins: [contentTypeMixin],
      computed: {
        contentType() {
          return 'incoming_email';
        },
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isEmailContentType).toBe(true);
  });

  it('returns false if contentType is not incoming_email', () => {
    const Component = {
      render() {},
      mixins: [contentTypeMixin],
      computed: {
        contentType() {
          return 'input_select';
        },
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isEmailContentType).toBe(false);
  });
});
