import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import { shallowMount } from '@vue/test-utils';
import rtlMixin from 'shared/mixins/rtlMixin';

describe('rtlMixin', () => {
  it('returns is direction right-to-left view', () => {
    const Component = {
      render() {},
      mixins: [rtlMixin, uiSettingsMixin],
      data() {
        return { uiSettings: { rtl_view: true } };
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isRTLView).toBe(true);
  });

  it('returns is direction left-to-right view', () => {
    const Component = {
      render() {},
      mixins: [rtlMixin, uiSettingsMixin],
      data() {
        return { uiSettings: { rtl_view: false } };
      },
    };
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isRTLView).toBe(false);
  });
});
