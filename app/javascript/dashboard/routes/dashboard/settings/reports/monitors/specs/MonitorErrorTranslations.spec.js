import { shallowMount, flushPromises } from '@vue/test-utils';
import { ref } from 'vue';
import { createI18n } from 'vue-i18n';
import report from 'dashboard/i18n/locale/en/report.json';
import MonitorsAPI from 'dashboard/api/monitors';
import MonitorForm from '../MonitorForm.vue';
import MonitorActionDialog from '../MonitorActionDialog.vue';

vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({ accountId: ref(1) }),
}));
vi.mock('dashboard/components-next/dialog/Dialog.vue', () => ({
  default: {
    name: 'Dialog',
    template: '<div><slot /></div>',
    methods: { close: vi.fn(), open: vi.fn() },
  },
}));
vi.mock('dashboard/api/monitors', () => ({
  default: { preview: vi.fn(), create: vi.fn(), update: vi.fn() },
}));

const global = {
  plugins: [
    createI18n({
      legacy: false,
      locale: 'fr',
      fallbackLocale: 'en',
      messages: { en: report, fr: {} },
      missingWarn: false,
      fallbackWarn: false,
    }),
  ],
  renderStubDefaultSlot: true,
  stubs: { Dialog: false },
};

describe('monitor error translations with an untranslated locale', () => {
  let wrapper;
  afterEach(() => wrapper?.unmount());

  it.each(['not_configured', 'monthly_limit', 'unknown_error'])(
    'uses the English preview error or fallback for %s',
    async code => {
      MonitorsAPI.preview.mockRejectedValue({
        response: { data: { error: code } },
      });
      wrapper = shallowMount(MonitorForm, { global });
      wrapper.vm.open({ condition: 'Mentions refunds' });
      await wrapper.vm.$nextTick();
      wrapper.findComponent({ name: 'Button' }).vm.$emit('click');
      await flushPromises();

      expect(wrapper.find('[role="alert"]').text()).toBe(
        report.MONITORS.ERRORS[code.toUpperCase()] ||
          report.MONITORS.PREVIEW_FAILED
      );
    }
  );

  it.each(['monitor_limit', 'monthly_limit', 'unknown_error'])(
    'uses the English creation error or fallback for %s',
    async code => {
      MonitorsAPI.create.mockRejectedValue({
        response: { data: { error: code } },
      });
      wrapper = shallowMount(MonitorForm, { global });
      wrapper.vm.open({ name: 'Refunds', condition: 'Mentions refunds' });
      await wrapper.vm.$nextTick();
      wrapper.findComponent({ name: 'Dialog' }).vm.$emit('confirm');
      await flushPromises();

      expect(wrapper.find('[role="alert"]').text()).toBe(
        report.MONITORS.ERRORS[code.toUpperCase()] ||
          report.MONITORS.ERRORS.SAVE_FAILED
      );
    }
  );

  it.each(['invalid_parameters', 'unknown_error', 'monitor_changed'])(
    'uses the English action error or fallback for %s',
    async code => {
      MonitorsAPI.update.mockRejectedValue({
        response: { data: { error: code } },
      });
      wrapper = shallowMount(MonitorActionDialog, { global });
      wrapper.vm.open('edit', {
        id: 1,
        name: 'Refunds',
        condition: 'Mentions refunds',
        collection_version: 0,
      });
      await wrapper.vm.$nextTick();
      wrapper.findComponent({ name: 'Dialog' }).vm.$emit('confirm');
      await flushPromises();

      expect(wrapper.find('[role="alert"]').text()).toBe(
        report.MONITORS.ERRORS[code.toUpperCase()] ||
          report.MONITORS.ERRORS.SAVE_FAILED
      );
      if (code === 'monitor_changed') {
        expect(wrapper.emitted('changed')).toEqual([
          [report.MONITORS.ERRORS.MONITOR_CHANGED],
        ]);
      }
    }
  );
});
