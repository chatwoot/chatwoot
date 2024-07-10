import { shallowMount } from '@vue/test-utils';
import rtlMixin from 'shared/mixins/rtlMixin';

describe('rtlMixin', () => {
  const createComponent = rtl_view => {
    return shallowMount({
      render() {},
      mixins: [rtlMixin],
      computed: {
        uiSettings() {
          return { rtl_view };
        },
      },
    });
  };

  it('returns is direction right-to-left view', () => {
    const wrapper = createComponent(true);
    expect(wrapper.vm.isRTLView).toBe(true);
  });

  it('returns is direction left-to-right view', () => {
    const wrapper = createComponent(false);
    expect(wrapper.vm.isRTLView).toBe(false);
  });
});
