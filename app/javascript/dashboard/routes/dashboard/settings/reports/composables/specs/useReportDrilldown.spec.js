import { flushPromises, mount } from '@vue/test-utils';
import ReportsAPI from 'dashboard/api/reports';
import { useReportDrilldown } from '../useReportDrilldown';

vi.mock('dashboard/api/reports', () => ({
  default: {
    getDrilldown: vi.fn(),
  },
}));

const deferredPromise = () => {
  let resolve;
  let reject;
  const promise = new Promise((resolvePromise, rejectPromise) => {
    resolve = resolvePromise;
    reject = rejectPromise;
  });

  return { promise, resolve, reject };
};

const drilldownRequest = overrides => ({
  metric: 'conversations_count',
  bucketTimestamp: 1,
  from: 1621103400,
  to: 1621621800,
  type: 'account',
  groupBy: 'day',
  businessHours: false,
  ...overrides,
});

describe('useReportDrilldown', () => {
  const mountComposable = () =>
    mount({
      setup() {
        return useReportDrilldown();
      },
      template: '<div />',
    });

  afterEach(() => {
    vi.clearAllMocks();
  });

  it('does not request drilldown again for an identical active request', async () => {
    const request = deferredPromise();
    ReportsAPI.getDrilldown.mockReturnValue(request.promise);

    const wrapper = mountComposable();
    wrapper.vm.open(drilldownRequest());
    wrapper.vm.open(drilldownRequest());

    expect(ReportsAPI.getDrilldown).toHaveBeenCalledTimes(1);
  });

  it('aborts an in-flight request when a newer request is opened', async () => {
    const firstRequest = deferredPromise();
    const secondRequest = deferredPromise();
    let firstSignal;

    ReportsAPI.getDrilldown
      .mockImplementationOnce(({ signal }) => {
        firstSignal = signal;
        return firstRequest.promise;
      })
      .mockReturnValueOnce(secondRequest.promise);

    const wrapper = mountComposable();
    wrapper.vm.open(drilldownRequest({ bucketTimestamp: 1 }));
    wrapper.vm.open(drilldownRequest({ bucketTimestamp: 2 }));

    expect(firstSignal.aborted).toBe(true);
  });

  it('passes an abort signal to drilldown requests', async () => {
    const request = deferredPromise();
    ReportsAPI.getDrilldown.mockReturnValue(request.promise);

    const wrapper = mountComposable();
    wrapper.vm.open(drilldownRequest());

    expect(ReportsAPI.getDrilldown).toHaveBeenCalledWith(
      expect.objectContaining({
        page: 1,
        signal: expect.any(AbortSignal),
      })
    );
  });

  it('ignores stale responses when a newer request is opened first', async () => {
    const firstRequest = deferredPromise();
    const secondRequest = deferredPromise();
    ReportsAPI.getDrilldown
      .mockReturnValueOnce(firstRequest.promise)
      .mockReturnValueOnce(secondRequest.promise);

    const wrapper = mountComposable();
    wrapper.vm.open(drilldownRequest({ bucketTimestamp: 1 }));
    wrapper.vm.open(drilldownRequest({ bucketTimestamp: 2 }));

    secondRequest.resolve({
      data: {
        meta: { current_page: 1, total_count: 1 },
        payload: [{ id: 'second' }],
      },
    });
    await flushPromises();

    expect(wrapper.vm.records).toEqual([{ id: 'second' }]);
    expect(wrapper.vm.meta).toEqual({ current_page: 1, total_count: 1 });

    firstRequest.resolve({
      data: {
        meta: { current_page: 1, total_count: 1 },
        payload: [{ id: 'first' }],
      },
    });
    await flushPromises();

    expect(wrapper.vm.records).toEqual([{ id: 'second' }]);
    expect(wrapper.vm.meta).toEqual({ current_page: 1, total_count: 1 });
  });
});
