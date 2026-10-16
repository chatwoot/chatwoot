import { defineComponent, h, nextTick, ref } from 'vue';
import { mount } from '@vue/test-utils';
import { useSlaStatus } from '../useSlaStatus';

const currentTimestamp = 1750000000;

const mountComposable = ({ appliedSla, chat, slaEvents = ref([]) }) => {
  let composable;
  const wrapper = mount(
    defineComponent({
      setup() {
        composable = useSlaStatus({ appliedSla, chat, slaEvents });
        return () => h('div');
      },
    })
  );

  return { wrapper, ...composable };
};

describe('useSlaStatus', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date(currentTimestamp * 1000));
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it('evaluates immediately and refreshes active SLAs every minute', () => {
    const appliedSla = ref({
      sla_frt_due_at: currentTimestamp + 120,
    });
    const chat = ref({
      first_reply_created_at: null,
      status: 'open',
    });

    const { slaStatus, wrapper } = mountComposable({ appliedSla, chat });

    expect(slaStatus.value.threshold).toBe('2m');

    vi.advanceTimersByTime(60000);

    expect(slaStatus.value.threshold).toBe('1m');
    wrapper.unmount();
  });

  it('refreshes and stops the timer when the chat object is replaced', async () => {
    const appliedSla = ref({
      sla_frt_due_at: currentTimestamp + 120,
    });
    const chat = ref({
      first_reply_created_at: null,
      status: 'open',
    });

    const { slaStatus, wrapper } = mountComposable({ appliedSla, chat });

    chat.value = { status: 'resolved' };
    await nextTick();

    expect(slaStatus.value.type).toBe('');
    expect(vi.getTimerCount()).toBe(0);
    wrapper.unmount();
  });

  it('restarts the timer when a resolved chat is reopened in place', async () => {
    const appliedSla = ref({
      sla_frt_due_at: currentTimestamp + 120,
    });
    const chat = ref({
      first_reply_created_at: null,
      status: 'open',
    });

    const { slaStatus, wrapper } = mountComposable({ appliedSla, chat });

    chat.value.status = 'resolved';
    appliedSla.value.sla_completed_at = currentTimestamp;
    await nextTick();

    expect(slaStatus.value.type).toBe('');
    expect(vi.getTimerCount()).toBe(0);

    chat.value.status = 'open';
    await nextTick();

    expect(slaStatus.value.type).toBe('FRT');
    expect(vi.getTimerCount()).toBe(1);
    wrapper.unmount();
  });

  it('clears the timer when its component unmounts', () => {
    const appliedSla = ref({
      sla_frt_due_at: currentTimestamp + 120,
    });
    const chat = ref({
      first_reply_created_at: null,
      status: 'open',
    });

    const { wrapper } = mountComposable({ appliedSla, chat });

    expect(vi.getTimerCount()).toBe(1);

    wrapper.unmount();

    expect(vi.getTimerCount()).toBe(0);
  });
});
