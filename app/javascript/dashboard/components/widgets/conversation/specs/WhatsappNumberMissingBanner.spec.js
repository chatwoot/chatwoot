import { mount, flushPromises } from '@vue/test-utils';
import ConversationAPI from 'dashboard/api/inbox/conversation';
import WhatsappNumberMissingBanner from '../WhatsappNumberMissingBanner.vue';

vi.mock('dashboard/api/inbox/conversation', () => ({
  default: { recheckWhatsappNumber: vi.fn() },
}));

const NOW = new Date('2026-10-16T18:00:00Z');
const hoursAgo = hours => Math.floor(NOW.getTime() / 1000) - hours * 3600;

const mountBanner = conversation =>
  mount(WhatsappNumberMissingBanner, {
    props: { conversation: { id: 144873, messages: [], ...conversation } },
    global: { stubs: { Banner: { template: '<div class="banner" />' } } },
  });

describe('WhatsappNumberMissingBanner', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(NOW);
    ConversationAPI.recheckWhatsappNumber.mockResolvedValue({});
  });

  afterEach(() => vi.useRealTimers());

  it('asks again on open once the answer is older than the window', async () => {
    const wrapper = mountBanner({ whatsapp_missing_checked_at: hoursAgo(48) });
    await flushPromises();

    expect(wrapper.find('.banner').exists()).toBe(true);
    expect(ConversationAPI.recheckWhatsappNumber).toHaveBeenCalledWith(144873);
  });

  it('does not ask again inside the window', async () => {
    const wrapper = mountBanner({ whatsapp_missing_checked_at: hoursAgo(1) });
    await flushPromises();

    expect(wrapper.find('.banner').exists()).toBe(true);
    expect(ConversationAPI.recheckWhatsappNumber).not.toHaveBeenCalled();
  });

  // A failed recheck is "unknown": the banner keeps the last real answer.
  it('keeps the banner when the recheck fails', async () => {
    ConversationAPI.recheckWhatsappNumber.mockRejectedValue(new Error('500'));

    const wrapper = mountBanner({ whatsapp_missing_checked_at: hoursAgo(48) });
    await flushPromises();

    expect(wrapper.find('.banner').exists()).toBe(true);
  });

  // Every update replaces the conversation object; only a new id or date is a reason to ask.
  it('does not ask again when an unrelated update replaces the conversation', async () => {
    ConversationAPI.recheckWhatsappNumber.mockRejectedValue(new Error('500'));
    const checkedAt = hoursAgo(48);
    const wrapper = mountBanner({ whatsapp_missing_checked_at: checkedAt });
    await flushPromises();

    await wrapper.setProps({
      conversation: {
        id: 144873,
        status: 'pending',
        whatsapp_missing_checked_at: checkedAt,
        messages: [],
      },
    });
    await flushPromises();

    expect(ConversationAPI.recheckWhatsappNumber).toHaveBeenCalledTimes(1);
  });

  it('shows nothing and asks nothing for a number not flagged', async () => {
    const wrapper = mountBanner({ whatsapp_missing_checked_at: null });
    await flushPromises();

    expect(wrapper.find('.banner').exists()).toBe(false);
    expect(ConversationAPI.recheckWhatsappNumber).not.toHaveBeenCalled();
  });

  it('hides as soon as the server pushes the cleared flag', async () => {
    const wrapper = mountBanner({ whatsapp_missing_checked_at: hoursAgo(1) });
    await wrapper.setProps({
      conversation: {
        id: 144873,
        whatsapp_missing_checked_at: null,
        messages: [],
      },
    });

    expect(wrapper.find('.banner').exists()).toBe(false);
  });
});
