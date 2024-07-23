import { shallowMount } from '@vue/test-utils';
import rtlMixin from 'shared/mixins/rtlMixin';
import { useUiSettings } from 'dashboard/composables/useUiSettings';

vi.mock('dashboard/composables/useUiSettings');

describe('rtlMixin', () => {
  const createComponent = rtl_view => {
    useUiSettings.mockReturnValue({
      uiSettings: { rtl_view },
      updateUISettings: vi.fn(),
    });

    return shallowMount({
      render() {},
      mixins: [rtlMixin],
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
