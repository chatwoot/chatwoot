import { shallowMount, flushPromises } from '@vue/test-utils';
import { computed, reactive, ref } from 'vue';
import { createI18n } from 'vue-i18n';
import MonitorShow from '../MonitorShow.vue';
import MonitorsAPI from 'dashboard/api/monitors';
import report from 'dashboard/i18n/locale/en/report.json';

const state = vi.hoisted(() => ({
  route: null,
  refresh: null,
  refreshOptions: null,
  router: null,
  account: null,
  i18n: null,
}));
vi.mock('vue-router', async importOriginal => ({
  ...(await importOriginal()),
  useRoute: () => state.route,
  useRouter: () => state.router,
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
  useMonitorRefresh: (refresh, options) => {
    state.refresh = refresh;
    state.refreshOptions = options;
  },
}));
vi.mock('dashboard/api/monitors', () => ({
  default: {
    timeseries: vi.fn(),
    update: vi.fn(),
    resume: vi.fn(),
    retry: vi.fn(),
  },
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
      MonitorActionDialog: false,
      TextArea: false,
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
    state.router = { push: vi.fn(), replace: vi.fn() };
    state.i18n = { t: key => key, te: () => true, locale: ref('en') };
    MonitorsAPI.timeseries.mockReset();
    MonitorsAPI.update.mockReset();
    MonitorsAPI.resume.mockReset();
    MonitorsAPI.retry.mockReset();
    MonitorsAPI.timeseries.mockImplementation((id, params) =>
      Promise.resolve(responseFor(params))
    );
  });
  afterEach(() => {
    wrapper?.unmount();
    vi.useRealTimers();
  });

  describe('retry evaluations', () => {
    beforeEach(async () => {
      MonitorsAPI.timeseries.mockImplementation(async (id, params) => {
        const response = responseFor(params);
        response.data.monitor.processing = {
          state: 'needs_attention',
          errors: 1,
          error_codes: ['provider_busy'],
        };
        return response;
      });
      wrapper = shallowMount(MonitorShow, mountOptions);
      await flushPromises();
    });

    it('clears the notice and refreshes the current monitor after a successful retry', async () => {
      MonitorsAPI.retry.mockResolvedValue({ data: {} });
      wrapper
        .findComponent({ name: 'MonitorActionDialog' })
        .vm.$emit('changed', 'MONITORS.RESULTS_UPDATED');
      await flushPromises();
      expect(
        wrapper
          .findAllComponents({ name: 'Banner' })
          .some(banner => banner.props('color') === 'blue')
      ).toBe(true);
      wrapper
        .findAllComponents({ name: 'Banner' })
        .find(banner => banner.props('actionLabel') === 'MONITORS.RETRY')
        .vm.$emit('action');
      await flushPromises();

      expect(MonitorsAPI.retry).toHaveBeenCalledWith(
        '10',
        expect.any(AbortSignal)
      );
      expect(
        wrapper
          .findAllComponents({ name: 'Banner' })
          .some(banner => banner.props('color') === 'blue')
      ).toBe(false);
      expect(MonitorsAPI.timeseries).toHaveBeenCalledTimes(3);
    });

    it('sends one retry while the first is still pending', async () => {
      let finish;
      MonitorsAPI.retry.mockImplementation(
        () =>
          new Promise(resolve => {
            finish = resolve;
          })
      );
      const retryButton = () =>
        wrapper
          .findAllComponents({ name: 'Banner' })
          .find(banner => banner.props('actionLabel') === 'MONITORS.RETRY');
      retryButton().vm.$emit('action');
      await wrapper.vm.$nextTick();
      retryButton().vm.$emit('action');

      expect(MonitorsAPI.retry).toHaveBeenCalledTimes(1);
      expect(retryButton().props('isLoading')).toBe(true);
      finish({ data: {} });
      await flushPromises();
      expect(retryButton().props('isLoading')).toBe(false);
    });

    it('shows a retry failure on the current monitor', async () => {
      MonitorsAPI.retry.mockRejectedValue({
        response: { data: { error: 'monthly_limit' } },
      });
      wrapper
        .findAllComponents({ name: 'Banner' })
        .find(banner => banner.props('actionLabel') === 'MONITORS.RETRY')
        .vm.$emit('action');
      await flushPromises();

      expect(wrapper.find('[role="alert"]').text()).toBe(
        'MONITORS.ERRORS.MONTHLY_LIMIT'
      );
      expect(MonitorsAPI.timeseries).toHaveBeenCalledTimes(1);
    });

    it.each([
      ['success', 'monitor'],
      ['failure', 'monitor'],
      ['success', 'account'],
      ['failure', 'account'],
      ['success', 'return'],
      ['failure', 'return'],
      ['success', 'unmount'],
    ])(
      'discards a late %s after %s navigation',
      async (outcome, navigation) => {
        let complete;
        MonitorsAPI.retry.mockImplementation(
          () =>
            new Promise((resolve, reject) => {
              complete = outcome === 'success' ? resolve : reject;
            })
        );
        wrapper
          .findAllComponents({ name: 'Banner' })
          .find(banner => banner.props('actionLabel') === 'MONITORS.RETRY')
          .vm.$emit('action');
        const signal = MonitorsAPI.retry.mock.lastCall[1];
        if (navigation === 'unmount') {
          wrapper.unmount();
        } else if (navigation === 'account') {
          state.route.params.accountId = '2';
        } else {
          state.route.params.monitorId = '11';
        }
        await flushPromises();
        if (navigation === 'return') {
          state.route.params.monitorId = '10';
          await flushPromises();
        }
        expect(signal.aborted).toBe(true);
        const calls = MonitorsAPI.timeseries.mock.calls.length;
        complete({ data: {}, response: { data: { error: 'monthly_limit' } } });
        await flushPromises();

        expect(MonitorsAPI.timeseries).toHaveBeenCalledTimes(calls);
        expect(
          wrapper
            .findAllComponents({ name: 'Banner' })
            .some(banner => banner.props('color') === 'blue')
        ).toBe(false);
        expect(wrapper.text()).not.toContain('MONITORS.ERRORS.MONTHLY_LIMIT');
      }
    );
  });

  it('requests the selected preset range ending now', async () => {
    wrapper = shallowMount(MonitorShow, mountOptions);
    await flushPromises();
    wrapper
      .findComponent({ name: 'MonitorChartFilters' })
      .vm.$emit('update:modelValue', { range: 15, interval: 'hour' });
    await flushPromises();

    const now = Date.now() / 1000;
    expect(MonitorsAPI.timeseries.mock.lastCall[1]).toEqual({
      since: now - 15 * 86400,
      until: now,
      interval: 'hour',
      timezone: 'UTC',
    });
  });

  it('clears the deleted monitor and leaves its detail route on a tombstone event', async () => {
    wrapper = shallowMount(MonitorShow, mountOptions);
    await flushPromises();

    state.refreshOptions.onDeleted();
    await flushPromises();

    expect(wrapper.findComponent({ name: 'BarChart' }).exists()).toBe(false);
    expect(state.router.replace).toHaveBeenCalledWith({
      name: 'monitor_reports_index',
    });
  });

  it.each(['monitor', 'account'])(
    'keeps the applied filters after %s navigation',
    async destination => {
      wrapper = shallowMount(MonitorShow, mountOptions);
      await flushPromises();
      const applied = { range: 30, interval: 'six_hours' };
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
      expect(
        wrapper
          .findComponent({ name: 'MonitorChartFilters' })
          .props('modelValue')
      ).toEqual(applied);
    }
  );

  it('edits both name and description using the version shown when the editor opened', async () => {
    wrapper = shallowMount(MonitorShow, mountOptions);
    await flushPromises();
    wrapper
      .findAllComponents({ name: 'Button' })
      .find(button => button.attributes('aria-label') === 'MONITORS.EDIT')
      .vm.$emit('click');
    await wrapper.vm.$nextTick();
    wrapper
      .findComponent({ name: 'Input' })
      .vm.$emit('update:modelValue', ' Payments ');
    await wrapper.find('textarea').setValue(' Conversations about payments ');
    MonitorsAPI.timeseries.mockImplementation((id, params) => {
      const response = responseFor(params);
      response.data.monitor.collection_version = 1;
      return Promise.resolve(response);
    });
    await state.refresh();
    MonitorsAPI.update.mockResolvedValue({ data: {} });
    wrapper.findComponent({ name: 'Dialog' }).vm.$emit('confirm');
    await flushPromises();

    expect(MonitorsAPI.update).toHaveBeenCalledWith('10', {
      name: 'Payments',
      condition: 'Conversations about payments',
      collection_version: 0,
    });
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
    const labels = wrapper
      .findAllComponents({ name: 'Button' })
      .map(button => button.attributes('aria-label'));
    expect(labels).not.toContain('MONITORS.PAUSE');
    expect(labels).toContain('MONITORS.DELETE');
  });

  it('pauses through the confirmation dialog and retains the chart', async () => {
    wrapper = shallowMount(MonitorShow, mountOptions);
    await flushPromises();
    MonitorsAPI.update.mockResolvedValue({ data: {} });
    const pausedAt = Math.ceil(Date.now() / 1000) + 1;
    MonitorsAPI.timeseries.mockImplementation((id, params) => {
      const response = responseFor(params);
      response.data.monitor.paused_at = pausedAt;
      response.data.monitor.processing.state = 'paused';
      return Promise.resolve(response);
    });
    wrapper
      .findAllComponents({ name: 'Button' })
      .find(button => button.attributes('aria-label') === 'MONITORS.PAUSE')
      .vm.$emit('click');
    await wrapper.vm.$nextTick();
    wrapper.findComponent({ name: 'Dialog' }).vm.$emit('confirm');
    await flushPromises();

    expect(MonitorsAPI.update).toHaveBeenCalledWith('10', { paused: true });
    expect(MonitorsAPI.timeseries.mock.lastCall[1].until).toBe(pausedAt);
    expect(wrapper.findComponent({ name: 'BarChart' }).exists()).toBe(true);
    expect(wrapper.text()).toContain('MONITORS.PAUSED_HELP');
  });

  it.each(['catch_up', 'from_now'])(
    'resumes with the selected %s mode and restores the live date range',
    async mode => {
      let paused = true;
      const pausedAt = Math.floor(Date.now() / 1000) - 86400;
      MonitorsAPI.timeseries.mockImplementation((id, params) => {
        const response = responseFor(params);
        response.data.monitor.paused_at = paused ? pausedAt : null;
        response.data.monitor.collection_version = paused ? 1 : 2;
        response.data.monitor.processing.state = paused ? 'paused' : 'live';
        return Promise.resolve(response);
      });
      MonitorsAPI.resume.mockImplementation(async () => {
        paused = false;
        return { data: {} };
      });
      wrapper = shallowMount(MonitorShow, mountOptions);
      await flushPromises();
      wrapper
        .findAllComponents({ name: 'Button' })
        .find(button => button.attributes('aria-label') === 'MONITORS.RESUME')
        .vm.$emit('click');
      await wrapper.vm.$nextTick();
      expect(wrapper.findAll('input[type="radio"]')).toHaveLength(2);
      await wrapper.find(`input[value="${mode}"]`).setValue();
      wrapper.findComponent({ name: 'Dialog' }).vm.$emit('confirm');
      await flushPromises();

      expect(MonitorsAPI.resume).toHaveBeenCalledWith('10', {
        mode,
        collection_version: 1,
      });
      expect(MonitorsAPI.timeseries.mock.lastCall[1].until).toBe(
        Math.floor(Date.now() / 1000)
      );
      expect(wrapper.findComponent({ name: 'BarChart' }).exists()).toBe(true);
      expect(
        wrapper
          .findAllComponents({ name: 'Button' })
          .map(button => button.attributes('aria-label'))
      ).toContain('MONITORS.PAUSE');
    }
  );

  it('clears a stale conflict notice once an action succeeds', async () => {
    wrapper = shallowMount(MonitorShow, mountOptions);
    await flushPromises();
    const pauseButton = () =>
      wrapper
        .findAllComponents({ name: 'Button' })
        .find(button => button.attributes('aria-label') === 'MONITORS.PAUSE');
    MonitorsAPI.update.mockRejectedValueOnce({
      response: { data: { error: 'monitor_changed' } },
    });
    pauseButton().vm.$emit('click');
    await wrapper.vm.$nextTick();
    wrapper.findComponent({ name: 'Dialog' }).vm.$emit('confirm');
    await flushPromises();
    expect(wrapper.find('[role="status"]').text()).toBe(
      'MONITORS.ERRORS.MONITOR_CHANGED'
    );

    MonitorsAPI.update.mockResolvedValueOnce({ data: {} });
    pauseButton().vm.$emit('click');
    await wrapper.vm.$nextTick();
    wrapper.findComponent({ name: 'Dialog' }).vm.$emit('confirm');
    await flushPromises();
    expect(wrapper.text()).not.toContain('MONITORS.ERRORS.MONITOR_CHANGED');
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
      'MONITORS.ERRORS.PROVIDER_BUSY'
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
        report.MONITORS.ERRORS[code.toUpperCase()] ||
          report.MONITORS.ERRORS.FETCH_FAILED
      );
    }
  );
});
