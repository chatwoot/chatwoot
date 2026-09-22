import { shallowMount, flushPromises } from '@vue/test-utils';
import { computed, reactive, ref } from 'vue';
import MonitorShow from '../MonitorShow.vue';
import MonitorsAPI from 'dashboard/api/monitors';

const state = vi.hoisted(() => ({ route: null, refresh: null, account: null }));
vi.mock('vue-router', async importOriginal => ({
  ...(await importOriginal()),
  useRoute: () => state.route,
  useRouter: () => ({ push: vi.fn() }),
}));
vi.mock('dashboard/composables/useAccount', () => ({
  useAccount: () => ({
    accountId: computed(() => Number(state.route.params.accountId)),
    currentAccount: computed(() => state.account),
    accountScopedRoute: name => ({ name }),
  }),
}));
vi.mock('dashboard/composables/useAdmin', () => ({
  useAdmin: () => ({ isAdmin: ref(true) }),
}));
vi.mock('vue-i18n', async importOriginal => ({
  ...(await importOriginal()),
  useI18n: () => ({ t: key => key, te: () => true }),
}));
vi.mock('dashboard/components-next/dialog/Dialog.vue', () => ({
  default: {
    name: 'Dialog',
    template: '<div><slot /></div>',
    methods: { close: vi.fn(), open: vi.fn() },
  },
}));
vi.mock('../useMonitorRefresh', () => ({
  useMonitorRefresh: refresh => {
    state.refresh = refresh;
  },
}));
vi.mock('dashboard/api/monitors', () => ({
  default: { timeseries: vi.fn(), update: vi.fn(), resume: vi.fn() },
}));

const responseFor = (params, count = 2) => ({
  data: {
    interval: params.interval,
    timezone: params.timezone,
    data_revision: 1,
    total_count: count,
    buckets: [
      { start: params.since, end: params.since + 3600, count, covered: true },
    ],
    monitor: {
      name: 'Refunds',
      collection_version: 0,
      condition: 'refund',
      processing: { state: 'live', error_codes: [] },
    },
  },
});

const mountOptions = {
  global: {
    renderStubDefaultSlot: true,
    stubs: {
      Dialog: false,
      Popover: {
        template: '<div><slot :is-open="true" /><slot name="content" /></div>',
        methods: { hide: vi.fn() },
      },
    },
  },
};

describe('MonitorShow', () => {
  let wrapper;
  beforeEach(() => {
    vi.useFakeTimers({ toFake: ['Date'] });
    vi.setSystemTime(new Date('2026-09-22T12:00:00Z'));
    state.route = reactive({ params: { accountId: '1', monitorId: '10' } });
    state.account = reactive({ reporting_timezone: 'UTC' });
    MonitorsAPI.timeseries.mockReset();
    MonitorsAPI.update.mockReset();
    MonitorsAPI.resume.mockReset();
    MonitorsAPI.timeseries.mockImplementation((id, params) =>
      Promise.resolve(responseFor(params))
    );
  });
  afterEach(() => {
    wrapper?.unmount();
    vi.useRealTimers();
  });

  it('uses the account timezone for custom calendar dates across daylight saving', async () => {
    state.account.reporting_timezone = 'America/New_York';
    wrapper = shallowMount(MonitorShow, mountOptions);
    await flushPromises();
    await wrapper.find('select').setValue('custom');
    const inputs = wrapper.findAllComponents({ name: 'Input' });
    inputs[0].vm.$emit('update:modelValue', '2026-03-05');
    inputs[1].vm.$emit('update:modelValue', '2026-03-11');
    await wrapper.find('form').trigger('submit');
    await flushPromises();

    expect(MonitorsAPI.timeseries.mock.lastCall[1]).toMatchObject({
      since: Date.parse('2026-03-05T05:00:00Z') / 1000,
      until: Date.parse('2026-03-12T04:00:00Z') / 1000,
      timezone: 'America/New_York',
    });
  });

  it('rejects custom ranges outside 7–30 calendar days without replacing the displayed report', async () => {
    wrapper = shallowMount(MonitorShow, mountOptions);
    await flushPromises();
    await wrapper.find('select').setValue('custom');
    const inputs = wrapper.findAllComponents({ name: 'Input' });
    inputs[0].vm.$emit('update:modelValue', '2026-08-23');
    inputs[1].vm.$emit('update:modelValue', '2026-09-22');
    await wrapper.find('form').trigger('submit');
    await flushPromises();

    expect(MonitorsAPI.timeseries).toHaveBeenCalledTimes(1);
    expect(wrapper.find('[role="alert"]').text()).toBe(
      'MONITORS.CUSTOM_RANGE_HELP'
    );
    expect(wrapper.findComponent({ name: 'BarChart' }).exists()).toBe(true);

    inputs[0].vm.$emit('update:modelValue', '2026-09-20');
    await wrapper.find('form').trigger('submit');
    expect(MonitorsAPI.timeseries).toHaveBeenCalledTimes(1);

    inputs[0].vm.$emit('update:modelValue', '2026-08-24');
    await wrapper.find('form').trigger('submit');
    await flushPromises();
    expect(MonitorsAPI.timeseries).toHaveBeenCalledTimes(2);
    expect(wrapper.find('[role="alert"]').exists()).toBe(false);
  });

  it('drills into the displayed chart snapshot while a refresh is pending', async () => {
    wrapper = shallowMount(MonitorShow, mountOptions);
    await flushPromises();
    const original = { ...MonitorsAPI.timeseries.mock.calls[0][1] };
    let finish;
    MonitorsAPI.timeseries.mockImplementation(
      () =>
        new Promise(resolve => {
          finish = resolve;
        })
    );
    vi.setSystemTime(new Date('2026-09-22T12:01:00Z'));
    state.refresh();
    wrapper
      .findComponent({ name: 'BarChart' })
      .vm.$emit('itemClick', { pointIndex: 0 });
    await wrapper.vm.$nextTick();

    expect(
      wrapper.findComponent({ name: 'MonitorDrilldown' }).props('request')
    ).toMatchObject(original);
    finish(responseFor(MonitorsAPI.timeseries.mock.calls[1][1]));
    await flushPromises();
    expect(
      wrapper.findComponent({ name: 'MonitorDrilldown' }).props('request')
    ).toBeNull();
  });

  it('closes a rolling edge bucket when its population changes without a membership revision', async () => {
    wrapper = shallowMount(MonitorShow, mountOptions);
    await flushPromises();
    wrapper
      .findComponent({ name: 'BarChart' })
      .vm.$emit('itemClick', { pointIndex: 0 });
    await wrapper.vm.$nextTick();
    vi.setSystemTime(new Date('2026-09-22T12:01:00Z'));
    await state.refresh();
    await flushPromises();

    expect(
      wrapper.findComponent({ name: 'MonitorDrilldown' }).props('request')
    ).toBeNull();
  });

  it('cannot restore an old account response after a route change with invalid draft dates', async () => {
    wrapper = shallowMount(MonitorShow, mountOptions);
    await flushPromises();
    const params = { ...MonitorsAPI.timeseries.mock.calls[0][1] };
    let finish;
    let signal;
    MonitorsAPI.timeseries.mockImplementation((id, filters, requestSignal) => {
      signal = requestSignal;
      return new Promise(resolve => {
        finish = resolve;
      });
    });
    state.refresh();
    await wrapper.findAll('select')[0].setValue('custom');
    const inputs = wrapper.findAllComponents({ name: 'Input' });
    inputs[0].vm.$emit('update:modelValue', '');
    await wrapper.vm.$nextTick();
    state.route.params.accountId = '2';
    state.route.params.monitorId = '20';
    await wrapper.vm.$nextTick();
    expect(signal.aborted).toBe(true);
    finish(responseFor(params));
    await flushPromises();
    expect(wrapper.findComponent({ name: 'BarChart' }).exists()).toBe(false);
  });

  it('keeps rolling charts and drilldowns anchored to the pause time', async () => {
    const pausedAt = Math.floor(
      new Date('2026-08-22T12:00:00Z').getTime() / 1000
    );
    MonitorsAPI.timeseries.mockImplementation((id, params) => {
      const response = responseFor(params);
      response.data.monitor.paused_at = pausedAt;
      response.data.monitor.processing.state = 'paused';
      return Promise.resolve(response);
    });
    wrapper = shallowMount(MonitorShow, mountOptions);
    await flushPromises();
    expect(MonitorsAPI.timeseries.mock.lastCall[1]).toMatchObject({
      until: pausedAt,
      since: pausedAt - 7 * 86400,
    });
    vi.setSystemTime(new Date('2026-09-23T12:00:00Z'));
    await state.refresh();
    expect(MonitorsAPI.timeseries.mock.lastCall[1].until).toBe(pausedAt);

    wrapper
      .findComponent({ name: 'BarChart' })
      .vm.$emit('itemClick', { pointIndex: 0 });
    await wrapper.vm.$nextTick();
    expect(
      wrapper.findComponent({ name: 'MonitorDrilldown' }).props('request').until
    ).toBe(pausedAt);
  });
});
