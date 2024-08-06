import { shallowMount } from '@vue/test-utils';
import rtlMixin from 'shared/mixins/rtlMixin';
import { useUISettings } from 'dashboard/composables/useUISettings';

vi.mock('dashboard/composables/useUISettings');

describe('rtlMixin', () => {
  const createComponent = rtl_view => {
    useUISettings.mockReturnValue({
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
