import { mount } from '@vue/test-utils';
import { defineComponent, nextTick } from 'vue';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { useMonitorRefresh } from '../useMonitorRefresh';

describe('useMonitorRefresh', () => {
  let wrapper;
  let refresh;
  let visibility;
  let monitorId;
  let onDeleted;
  const RefreshHost = defineComponent({
    setup() {
      useMonitorRefresh(refresh, { monitorId, onDeleted });
      return () => null;
    },
  });

  beforeEach(async () => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date('2026-09-22T12:00:00Z'));
    visibility = 'visible';
    vi.spyOn(document, 'visibilityState', 'get').mockImplementation(
      () => visibility
    );
    refresh = vi.fn();
    monitorId = null;
    onDeleted = vi.fn();
    wrapper = mount(RefreshHost);
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

  it('ignores other monitors when scoped to one', () => {
    wrapper.unmount();
    monitorId = 2;
    wrapper = mount(RefreshHost);

    emitter.emit(BUS_EVENTS.MONITOR_UPDATED, { account_id: 1, monitor_id: 3 });
    expect(refresh).not.toHaveBeenCalled();
    emitter.emit(BUS_EVENTS.MONITOR_UPDATED, { account_id: 1, monitor_id: 2 });
    expect(refresh).toHaveBeenCalledOnce();
  });

  it('handles a matching deletion immediately without refreshing a removed monitor', () => {
    wrapper.unmount();
    monitorId = 2;
    wrapper = mount(RefreshHost);

    emitter.emit(BUS_EVENTS.MONITOR_UPDATED, {
      account_id: 1,
      monitor_id: 3,
      deleted: true,
    });
    expect(onDeleted).not.toHaveBeenCalled();
    emitter.emit(BUS_EVENTS.MONITOR_UPDATED, {
      account_id: 1,
      monitor_id: 2,
      deleted: true,
    });
    expect(onDeleted).toHaveBeenCalledOnce();
    expect(refresh).not.toHaveBeenCalled();
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

  it('refreshes once when returning to the tab fires both focus and visibility events', () => {
    document.dispatchEvent(new Event('visibilitychange'));
    window.dispatchEvent(new Event('focus'));

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
