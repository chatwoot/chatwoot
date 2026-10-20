import { shallowMount } from '@vue/test-utils';
import { withFullI18n } from 'test-i18n';
import AutoResolve from './AutoResolve.vue';

const mocks = vi.hoisted(() => ({ updateAccount: vi.fn(), alert: vi.fn() }));
vi.mock('dashboard/composables/useAccount', async () => {
  const { ref } = await import('vue');
  return {
    useAccount: () => ({
      currentAccount: ref({ settings: { auto_resolve_after: 10 } }),
      updateAccount: mocks.updateAccount,
    }),
  };
});
vi.mock('dashboard/composables/store', async () => {
  const { ref } = await import('vue');
  return { useMapGetter: () => ref([]) };
});
vi.mock('dashboard/composables', () => ({ useAlert: mocks.alert }));

withFullI18n();

const stubs = {
  DurationInput: {
    props: ['modelValue'],
    emits: ['update:modelValue'],
    template:
      '<input data-test="duration" :value="modelValue" @input="$emit(\'update:modelValue\', Number($event.target.value))" />',
  },
  WithLabel: { template: '<div><slot /></div>' },
};

describe('AutoResolve duration translations', () => {
  const originalConfig = window.chatwootConfig;
  afterEach(() => {
    window.chatwootConfig = originalConfig;
  });

  it.each([
    [undefined, 9, 10],
    [30, 29, 30],
  ])(
    'renders the minimum %s in the real validation message',
    async (minimum, duration, expectedMinimum) => {
      window.chatwootConfig = { autoResolveMinMinutes: minimum };
      const wrapper = shallowMount(AutoResolve, {
        global: { stubs },
      });

      await wrapper.find('[data-test="duration"]').setValue(duration);
      await wrapper.find('form').trigger('submit');

      expect(mocks.updateAccount).not.toHaveBeenCalled();
      expect(mocks.alert).toHaveBeenCalledWith(
        `Auto resolve duration should be between ${expectedMinimum} minutes and 999 days`
      );
      wrapper.unmount();
    }
  );

  it.each([10, 30])('accepts the configured minimum of %s', async minimum => {
    window.chatwootConfig = { autoResolveMinMinutes: minimum };
    const wrapper = shallowMount(AutoResolve, { global: { stubs } });
    await wrapper.find('[data-test="duration"]').setValue(minimum);
    await wrapper.find('form').trigger('submit');

    expect(mocks.updateAccount).toHaveBeenCalledWith(
      expect.objectContaining({ auto_resolve_after: minimum }),
      { silent: true }
    );
    wrapper.unmount();
  });
});
