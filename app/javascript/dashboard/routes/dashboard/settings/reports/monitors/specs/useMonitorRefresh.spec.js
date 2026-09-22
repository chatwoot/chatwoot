import { mount } from '@vue/test-utils';
import { defineComponent, nextTick } from 'vue';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { useMonitorRefresh } from '../useMonitorRefresh';

describe('useMonitorRefresh', () => {
  let wrapper;
  let refresh;
  let visibility;

  beforeEach(async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-09-22T12:00:00Z'));
    visibility = 'visible';
    vi.spyOn(document, 'visibilityState', 'get').mockImplementation(
      () => visibility
    );
    refresh = vi.fn();
    wrapper = mount(
      defineComponent({
        setup() {
          useMonitorRefresh(refresh);
          return () => null;
        },
      })
    );
    await nextTick();
  });

  afterEach(() => {
    wrapper.unmount();
    vi.restoreAllMocks();
    vi.clearAllTimers();
    vi.useRealTimers();
  });

  it('refreshes for monitor changes, coalescing an event burst', async () => {
    emitter.emit(BUS_EVENTS.MONITOR_UPDATED, { account_id: 1 });
    expect(refresh).toHaveBeenCalledTimes(1);
    emitter.emit(BUS_EVENTS.MONITOR_UPDATED, { account_id: 1 });
    emitter.emit(BUS_EVENTS.MONITOR_UPDATED, { account_id: 1 });
    expect(refresh).toHaveBeenCalledTimes(1);

    await vi.advanceTimersByTimeAsync(2000);
    expect(refresh).toHaveBeenCalledTimes(2);
  });

  it('keeps the final evaluation update when it arrives during the refresh throttle', async () => {
    emitter.emit(BUS_EVENTS.MONITOR_UPDATED, { account_id: 1 });
    await vi.advanceTimersByTimeAsync(1000);
    emitter.emit(BUS_EVENTS.MONITOR_UPDATED, {
      account_id: 1,
      data_revision: 2,
    });
    expect(refresh).toHaveBeenCalledTimes(1);

    await vi.advanceTimersByTimeAsync(1000);
    expect(refresh).toHaveBeenCalledTimes(2);
  });

  it('does not refresh a hidden tab and catches up when it becomes visible', async () => {
    visibility = 'hidden';
    emitter.emit(BUS_EVENTS.MONITOR_UPDATED, { account_id: 1 });
    await vi.advanceTimersByTimeAsync(3000);
    expect(refresh).not.toHaveBeenCalled();

    visibility = 'visible';
    document.dispatchEvent(new Event('visibilitychange'));
    expect(refresh).toHaveBeenCalledOnce();
  });

  it('retains reconnect and periodic recovery when realtime events are missed', async () => {
    emitter.emit(BUS_EVENTS.WEBSOCKET_RECONNECT);
    expect(refresh).toHaveBeenCalledOnce();

    await vi.advanceTimersByTimeAsync(30000);
    expect(refresh).toHaveBeenCalledTimes(2);
  });

  it('ignores a pending trailing refresh and new events after navigation away', async () => {
    emitter.emit(BUS_EVENTS.MONITOR_UPDATED, { account_id: 1 });
    emitter.emit(BUS_EVENTS.MONITOR_UPDATED, { account_id: 1 });
    wrapper.unmount();
    refresh.mockClear();

    emitter.emit(BUS_EVENTS.MONITOR_UPDATED, { account_id: 1 });
    emitter.emit(BUS_EVENTS.WEBSOCKET_RECONNECT);
    await vi.advanceTimersByTimeAsync(30000);
    expect(refresh).not.toHaveBeenCalled();
  });
});
