import { shallowMount, flushPromises } from '@vue/test-utils';
import { computed, reactive, ref } from 'vue';
import { createI18n } from 'vue-i18n';
import MonitorShow from '../MonitorShow.vue';
import MonitorsAPI from 'dashboard/api/monitors';
import report from 'dashboard/i18n/locale/en/report.json';

const state = vi.hoisted(() => ({
  route: null,
  refresh: null,
  account: null,
  shouldPoll: null,
  i18n: null,
}));
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
  useI18n: () => state.i18n,
}));
vi.mock('dashboard/components-next/dialog/Dialog.vue', () => ({
  default: {
    name: 'Dialog',
    template: '<div><slot /></div>',
    methods: { close: vi.fn(), open: vi.fn() },
  },
}));
vi.mock('../useMonitorRefresh', () => ({
  useMonitorRefresh: (refresh, { shouldPoll }) => {
    state.refresh = refresh;
    state.shouldPoll = shouldPoll;
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
    state.i18n = { t: key => key, te: () => true, locale: ref('en') };
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

  it('uses only the applied range to control polling', async () => {
    wrapper = shallowMount(MonitorShow, mountOptions);
    await flushPromises();
    expect(state.shouldPoll()).toBe(true);

    wrapper
      .findComponent({ name: 'MonitorChartFilters' })
      .vm.$emit('update:modelValue', {
        range: 'custom',
        from: '2026-09-16',
        to: '2026-09-22',
        interval: 'day',
      });
    await flushPromises();
    expect(state.shouldPoll()).toBe(false);

    wrapper
      .findComponent({ name: 'MonitorChartFilters' })
      .vm.$emit('update:modelValue', { range: 30, interval: 'day' });
    await flushPromises();
    expect(state.shouldPoll()).toBe(true);
  });

  it.each(['2026-09-20T12:00:00Z', '2026-08-22T12:00:00Z'])(
    'ends custom dates at the pause at %s and keeps the applied dates after resume',
    async pauseTime => {
      let paused = true;
      MonitorsAPI.timeseries.mockImplementation(async (id, params) => {
        const response = responseFor(params);
        response.data.monitor.paused_at = paused
          ? Date.parse(pauseTime) / 1000
          : null;
        return response;
      });
      const pauseDate = pauseTime.slice(0, 10);
      const since = Date.parse(`${pauseDate}T00:00:00Z`) / 1000 - 6 * 86400;
      wrapper = shallowMount(MonitorShow, mountOptions);
      await flushPromises();
      wrapper
        .findComponent({ name: 'MonitorChartFilters' })
        .vm.$emit('update:modelValue', {
          range: 'custom',
          from: new Date(since * 1000).toISOString().slice(0, 10),
          to: pauseDate,
          interval: 'day',
        });
      await flushPromises();
      expect(MonitorsAPI.timeseries.mock.lastCall[1]).toMatchObject({
        since,
        until: Date.parse(pauseTime) / 1000,
      });
      expect(wrapper.findComponent({ name: 'BarChart' }).exists()).toBe(true);

      paused = false;
      await state.refresh();
      await flushPromises();
      expect(MonitorsAPI.timeseries.mock.lastCall[1]).toMatchObject({
        since,
        until: Date.parse(`${pauseDate}T00:00:00Z`) / 1000 + 86400,
      });
    }
  );

  it('uses the account timezone for custom calendar dates across daylight saving', async () => {
    state.account.reporting_timezone = 'America/New_York';
    wrapper = shallowMount(MonitorShow, mountOptions);
    await flushPromises();
    wrapper
      .findComponent({ name: 'MonitorChartFilters' })
      .vm.$emit('update:modelValue', {
        range: 'custom',
        from: '2026-03-05',
        to: '2026-03-11',
        interval: 'day',
      });
    await flushPromises();

    expect(MonitorsAPI.timeseries.mock.lastCall[1]).toMatchObject({
      since: Date.parse('2026-03-05T05:00:00Z') / 1000,
      until: Date.parse('2026-03-12T04:00:00Z') / 1000,
      timezone: 'America/New_York',
    });
  });

  it.each(['monitor', 'account'])(
    'loads applied custom filters after %s navigation',
    async destination => {
      wrapper = shallowMount(MonitorShow, mountOptions);
      await flushPromises();
      const applied = {
        range: 'custom',
        from: '2026-09-16',
        to: '2026-09-22',
        interval: 'day',
      };
      wrapper
        .findComponent({ name: 'MonitorChartFilters' })
        .vm.$emit('update:modelValue', applied);
      await flushPromises();
      const params = { ...MonitorsAPI.timeseries.mock.lastCall[1] };

      if (destination === 'account') state.route.params.accountId = '2';
      state.route.params.monitorId = '20';
      await flushPromises();

      expect(MonitorsAPI.timeseries.mock.lastCall.slice(0, 2)).toEqual([
        '20',
        params,
      ]);
      expect(wrapper.findComponent({ name: 'BarChart' }).exists()).toBe(true);
      expect(state.shouldPoll()).toBe(false);
      expect(
        wrapper
          .findComponent({ name: 'MonitorChartFilters' })
          .props('modelValue')
      ).toEqual(applied);
    }
  );

  it('extends a custom range ending today as time passes', async () => {
    wrapper = shallowMount(MonitorShow, mountOptions);
    await flushPromises();
    wrapper
      .findComponent({ name: 'MonitorChartFilters' })
      .vm.$emit('update:modelValue', {
        range: 'custom',
        from: '2026-09-16',
        to: '2026-09-22',
        interval: 'day',
      });
    await flushPromises();
    expect(MonitorsAPI.timeseries.mock.lastCall[1].until).toBe(
      Date.now() / 1000
    );

    vi.setSystemTime(new Date('2026-09-22T15:00:00Z'));
    await state.refresh();
    expect(MonitorsAPI.timeseries.mock.lastCall[1].until).toBe(
      Date.parse('2026-09-22T15:00:00Z') / 1000
    );

    vi.setSystemTime(new Date('2026-09-23T09:00:00Z'));
    await state.refresh();
    expect(MonitorsAPI.timeseries.mock.lastCall[1].until).toBe(
      Date.parse('2026-09-23T00:00:00Z') / 1000
    );
  });

  it('loads a valid default range when the destination paused before the applied custom range', async () => {
    MonitorsAPI.timeseries.mockImplementation((id, params) => {
      const response = responseFor(params);
      if (id === '20')
        response.data.monitor.paused_at =
          Date.parse('2026-08-20T12:00:00Z') / 1000;
      return Promise.resolve(response);
    });
    wrapper = shallowMount(MonitorShow, mountOptions);
    await flushPromises();
    wrapper
      .findComponent({ name: 'MonitorChartFilters' })
      .vm.$emit('update:modelValue', {
        range: 'custom',
        from: '2026-09-16',
        to: '2026-09-22',
        interval: 'day',
      });
    await flushPromises();
    state.route.params.monitorId = '20';
    await flushPromises();

    const boundary = Date.parse('2026-08-20T12:00:00Z') / 1000;
    expect(MonitorsAPI.timeseries.mock.lastCall[1]).toMatchObject({
      since: boundary - 7 * 86400,
      until: boundary,
    });
    expect(wrapper.findComponent({ name: 'BarChart' }).exists()).toBe(true);
    expect(
      wrapper.findComponent({ name: 'MonitorChartFilters' }).props('modelValue')
        .range
    ).toBe(7);
  });

  it('shortens the applied custom range when the destination paused inside it', async () => {
    const pausedAt = Date.parse('2026-09-20T12:00:00Z') / 1000;
    MonitorsAPI.timeseries.mockImplementation((id, params) => {
      const response = responseFor(params);
      if (id === '20') response.data.monitor.paused_at = pausedAt;
      return Promise.resolve(response);
    });
    wrapper = shallowMount(MonitorShow, mountOptions);
    await flushPromises();
    wrapper
      .findComponent({ name: 'MonitorChartFilters' })
      .vm.$emit('update:modelValue', {
        range: 'custom',
        from: '2026-09-10',
        to: '2026-09-22',
        interval: 'day',
      });
    await flushPromises();
    state.route.params.monitorId = '20';
    await flushPromises();

    expect(MonitorsAPI.timeseries.mock.lastCall[1]).toMatchObject({
      since: Date.parse('2026-09-10T00:00:00Z') / 1000,
      until: pausedAt,
    });
    expect(
      wrapper.findComponent({ name: 'MonitorChartFilters' }).props('modelValue')
        .to
    ).toBe('2026-09-20');
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
    expect(wrapper.findComponent({ name: 'MonitorDrilldown' }).exists()).toBe(
      false
    );
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

    expect(wrapper.findComponent({ name: 'MonitorDrilldown' }).exists()).toBe(
      false
    );
  });

  it('cannot restore an old account response after a route change', async () => {
    wrapper = shallowMount(MonitorShow, mountOptions);
    await flushPromises();
    const params = { ...MonitorsAPI.timeseries.mock.calls[0][1] };
    let finish;
    let signal;
    MonitorsAPI.timeseries.mockImplementation((id, filters, requestSignal) => {
      if (id === '20') return Promise.resolve(responseFor(filters, 5));
      signal = requestSignal;
      return new Promise(resolve => {
        finish = resolve;
      });
    });
    state.refresh();
    state.route.params.accountId = '2';
    state.route.params.monitorId = '20';
    await wrapper.vm.$nextTick();
    expect(signal.aborted).toBe(true);
    finish(responseFor(params));
    await flushPromises();
    expect(wrapper.findComponent({ name: 'BarChart' }).exists()).toBe(true);
    expect(
      wrapper.findComponent({ name: 'BarChart' }).props('data').series[0].data
    ).toEqual([5]);
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

  it('keeps the last chart when a refresh fails', async () => {
    wrapper = shallowMount(MonitorShow, mountOptions);
    await flushPromises();
    MonitorsAPI.timeseries.mockRejectedValue({
      response: { data: { error: 'provider_busy' } },
    });
    await state.refresh();
    await flushPromises();

    expect(wrapper.findComponent({ name: 'BarChart' }).exists()).toBe(true);
    expect(wrapper.find('[role="alert"]').text()).toBe(
      'MONITORS.ERRORS.provider_busy'
    );
  });

  it.each([
    'not_configured',
    'monthly_limit',
    'provider_busy',
    'unknown_error',
  ])(
    'uses the English fallback for %s when the current locale has no monitor translations',
    async code => {
      state.i18n = createI18n({
        legacy: false,
        locale: 'fr',
        fallbackLocale: 'en',
        messages: { en: report, fr: {} },
        missingWarn: false,
        fallbackWarn: false,
      }).global;
      MonitorsAPI.timeseries.mockRejectedValue({
        response: { data: { error: code } },
      });
      wrapper = shallowMount(MonitorShow, mountOptions);
      await flushPromises();

      expect(wrapper.find('[role="alert"]').text()).toBe(
        report.MONITORS.ERRORS[code] || report.MONITORS.ERRORS.fetch_failed
      );
    }
  );
});
