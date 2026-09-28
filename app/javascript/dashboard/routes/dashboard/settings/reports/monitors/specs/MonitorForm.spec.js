import { shallowMount, flushPromises } from '@vue/test-utils';
import { ref } from 'vue';
import MonitorForm from '../MonitorForm.vue';
import MonitorsAPI from 'dashboard/api/monitors';

const state = vi.hoisted(() => ({ accountId: null, now: null }));
vi.mock('@vueuse/core', async importOriginal => ({
  ...(await importOriginal()),
  useTimestamp: () => state.now,
}));
vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({ accountId: state.accountId }),
}));
vi.mock('vue-i18n', async importOriginal => ({
  ...(await importOriginal()),
  useI18n: () => ({
    t: (key, params) => (params?.count ? `${key}:${params.count}` : key),
    te: () => true,
  }),
}));
vi.mock('dashboard/components-next/dialog/Dialog.vue', () => ({
  default: {
    name: 'Dialog',
    template: '<div><slot /></div>',
    methods: { close: vi.fn(), open: vi.fn() },
  },
}));
vi.mock('dashboard/api/monitors', () => ({
  default: { create: vi.fn(), preview: vi.fn(), previewStatus: vi.fn() },
}));

describe('MonitorForm preview cooldown', () => {
  let wrapper;
  beforeEach(() => {
    vi.useFakeTimers({
      toFake: [
        'Date',
        'setInterval',
        'clearInterval',
        'setTimeout',
        'clearTimeout',
      ],
    });
    vi.setSystemTime(new Date('2026-09-22T12:00:00Z'));
    state.accountId = ref(1);
    state.now = ref(Date.now());
    MonitorsAPI.preview.mockReset();
    MonitorsAPI.previewStatus.mockReset();
    MonitorsAPI.create.mockReset();
    MonitorsAPI.preview.mockResolvedValue({
      data: { token: 'preview-token', retry_after: 30 },
    });
    MonitorsAPI.previewStatus.mockResolvedValue({
      data: { status: 'complete', sampled: 5, excluded: 0, payload: [] },
    });
    wrapper = shallowMount(MonitorForm, {
      global: {
        renderStubDefaultSlot: true,
        stubs: { Dialog: false, Button: false, TextArea: false },
      },
    });
  });
  afterEach(() => {
    wrapper.unmount();
    vi.useRealTimers();
  });

  it('shows results while preventing another preview until the cooldown expires', async () => {
    await wrapper.find('textarea').setValue('Refunds');
    const button = wrapper.findComponent({ name: 'Button' });
    button.vm.$emit('click');
    await flushPromises();
    expect(wrapper.text()).toContain('MONITORS.PREVIEW_COOLDOWN:30');
    await vi.advanceTimersByTimeAsync(2000);

    expect(wrapper.text()).toContain('MONITORS.PREVIEW_HELP');
    expect(button.element.disabled).toBe(true);
    button.vm.$emit('click');
    expect(MonitorsAPI.preview).toHaveBeenCalledTimes(1);
    await vi.advanceTimersByTimeAsync(28000);
    state.now.value = Date.now();
    await wrapper.vm.$nextTick();

    expect(button.element.disabled).toBe(false);
    expect(wrapper.text()).not.toContain('MONITORS.PREVIEW_COOLDOWN');
    button.vm.$emit('click');
    await flushPromises();
    expect(MonitorsAPI.preview).toHaveBeenCalledTimes(2);
  });

  it('keeps the cooldown when editing the condition or reopening the form', async () => {
    await wrapper.find('textarea').setValue('Refunds');
    const button = wrapper.findComponent({ name: 'Button' });
    button.vm.$emit('click');
    await flushPromises();
    await wrapper.find('textarea').setValue('WhatsApp BSUID');
    expect(button.element.disabled).toBe(true);
    wrapper.findComponent({ name: 'Dialog' }).vm.$emit('close');
    wrapper.vm.open();
    await wrapper.find('textarea').setValue('Automations');

    expect(wrapper.text()).toContain('MONITORS.PREVIEW_COOLDOWN:30');
    expect(button.element.disabled).toBe(true);
  });

  it('uses the remaining server cooldown when another tab already previewed', async () => {
    MonitorsAPI.preview.mockRejectedValue({
      response: { data: { error: 'preview_rate_limit', retry_after: 9 } },
    });
    await wrapper.find('textarea').setValue('Refunds');
    const button = wrapper.findComponent({ name: 'Button' });
    button.vm.$emit('click');
    await flushPromises();

    expect(wrapper.find('[role="alert"]').exists()).toBe(false);
    expect(wrapper.text()).toContain('MONITORS.PREVIEW_COOLDOWN:9');
    expect(button.element.disabled).toBe(true);
    await vi.advanceTimersByTimeAsync(9000);
    state.now.value = Date.now();
    await wrapper.vm.$nextTick();
    expect(button.element.disabled).toBe(false);
  });

  it('records the cooldown even when the condition changed before the request completed', async () => {
    let resolve;
    MonitorsAPI.preview.mockImplementation(
      () =>
        new Promise(done => {
          resolve = done;
        })
    );
    await wrapper.find('textarea').setValue('Refunds');
    const button = wrapper.findComponent({ name: 'Button' });
    button.vm.$emit('click');
    await wrapper.find('textarea').setValue('WhatsApp BSUID');
    resolve({ data: { token: 'old-condition', retry_after: 30 } });
    await flushPromises();
    await vi.advanceTimersByTimeAsync(2000);

    expect(button.element.disabled).toBe(true);
    expect(MonitorsAPI.previewStatus).not.toHaveBeenCalled();
  });

  it('displays provider capacity failures', async () => {
    MonitorsAPI.previewStatus.mockResolvedValue({
      data: { status: 'error', error: 'provider_busy' },
    });
    await wrapper.find('textarea').setValue('Refunds');
    wrapper.findComponent({ name: 'Button' }).vm.$emit('click');
    await flushPromises();
    await vi.advanceTimersByTimeAsync(2000);

    expect(wrapper.find('[role="alert"]').text()).toBe(
      'MONITORS.ERRORS.PROVIDER_BUSY'
    );
  });

  it('waits for each status response before checking again', async () => {
    let finish;
    MonitorsAPI.previewStatus.mockImplementation(
      () =>
        new Promise(resolve => {
          finish = resolve;
        })
    );
    await wrapper.find('textarea').setValue('Refunds');
    wrapper.findComponent({ name: 'Button' }).vm.$emit('click');
    await flushPromises();
    await vi.advanceTimersByTimeAsync(6000);
    expect(MonitorsAPI.previewStatus).toHaveBeenCalledTimes(1);

    finish({ data: { status: 'pending' } });
    await vi.advanceTimersByTimeAsync(1500);
    expect(MonitorsAPI.previewStatus).toHaveBeenCalledTimes(2);
  });

  it('shows a preview failure when the status request fails', async () => {
    MonitorsAPI.previewStatus.mockRejectedValue(new Error('network'));
    await wrapper.find('textarea').setValue('Refunds');
    wrapper.findComponent({ name: 'Button' }).vm.$emit('click');
    await flushPromises();

    expect(wrapper.find('[role="alert"]').text()).toBe(
      'MONITORS.PREVIEW_FAILED'
    );
  });

  it('opens prefilled with an example name and condition', async () => {
    wrapper.vm.open({ name: 'Refunds', condition: 'Mentions refunds' });
    await wrapper.vm.$nextTick();

    expect(wrapper.find('textarea').element.value).toBe('Mentions refunds');
    expect(wrapper.findComponent({ name: 'Input' }).props('modelValue')).toBe(
      'Refunds'
    );
  });

  it('opens a duplicate with only the condition', async () => {
    wrapper.vm.open({ condition: 'Mentions refunds' });
    await wrapper.vm.$nextTick();

    expect(wrapper.find('textarea').element.value).toBe('Mentions refunds');
    expect(wrapper.findComponent({ name: 'Input' }).props('modelValue')).toBe(
      ''
    );
  });

  it('keeps a reopened form when an earlier create request finishes', async () => {
    let finish;
    MonitorsAPI.create.mockImplementationOnce(
      () =>
        new Promise(resolve => {
          finish = resolve;
        })
    );
    wrapper.vm.open({ name: 'Old', condition: 'Old condition' });
    wrapper.findComponent({ name: 'Dialog' }).vm.$emit('confirm');
    await wrapper.vm.$nextTick();
    wrapper.findComponent({ name: 'Dialog' }).vm.$emit('close');
    wrapper.vm.open({ name: 'New', condition: 'New condition' });
    finish({ data: { id: 42 } });
    await flushPromises();

    expect(wrapper.emitted('created')).toBeUndefined();
    expect(wrapper.findComponent({ name: 'Input' }).props('modelValue')).toBe(
      'New'
    );
    expect(wrapper.find('textarea').element.value).toBe('New condition');
  });
});
