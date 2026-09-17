import { effectScope, ref } from 'vue';
import { flushPromises } from '@vue/test-utils';
import ConversationApi from 'dashboard/api/conversations';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { useCampaignHistory } from '../useCampaignHistory';

vi.mock('dashboard/api/conversations', () => ({
  default: { getCampaignHistory: vi.fn() },
}));
vi.mock('dashboard/composables/store');
vi.mock('dashboard/composables/useAccount');

describe('useCampaignHistory retry', () => {
  let scope;
  let chat;
  let history;

  beforeEach(() => {
    vi.clearAllMocks();
    chat = ref({
      id: 1,
      meta: { channel: INBOX_TYPES.WHATSAPP, sender: { id: 1 } },
      messages: [{ id: 1, created_at: 100 }],
    });
    useMapGetter.mockImplementation(key =>
      key === 'getSelectedChat' ? chat : ref(true)
    );
    useAccount.mockReturnValue({ isCloudFeatureEnabled: () => true });
    scope = effectScope();
  });

  afterEach(() => scope.stop());

  it.each([null, 10])(
    'retries the newest page after a failed automatic refresh with older cursor %s',
    async nextBefore => {
      ConversationApi.getCampaignHistory.mockResolvedValueOnce({
        data: {
          payload: [{ id: 10, sent_at: 90, source_id: 'campaign-10' }],
          meta: { next_before: nextBefore, first_message_id: 1 },
        },
      });
      history = scope.run(() => useCampaignHistory());
      await flushPromises();

      ConversationApi.getCampaignHistory.mockRejectedValueOnce(
        new Error('Network error')
      );
      chat.value.messages.push({ id: 2, created_at: 200 });
      await flushPromises();
      expect(history.campaignHistoryError.value).toBe(true);

      ConversationApi.getCampaignHistory.mockResolvedValueOnce({
        data: {
          payload: [
            { id: 11, sent_at: 150, source_id: 'campaign-11' },
            { id: 10, sent_at: 90, source_id: 'campaign-10' },
          ],
          meta: { next_before: null, first_message_id: 1 },
        },
      });
      await history.loadCampaignHistory();

      expect(ConversationApi.getCampaignHistory).toHaveBeenCalledTimes(3);
      expect(ConversationApi.getCampaignHistory).toHaveBeenLastCalledWith(1, {
        before: undefined,
        signal: expect.any(AbortSignal),
      });
      expect(history.campaignHistoryError.value).toBe(false);
      expect(history.visibleCampaignHistory.value.map(item => item.id)).toEqual(
        [11, 10]
      );
      expect(history.hasMoreCampaignHistory.value).toBe(nextBefore !== null);
    }
  );

  it('clears the failed refresh mode when switching conversations', async () => {
    ConversationApi.getCampaignHistory.mockResolvedValueOnce({
      data: {
        payload: [],
        meta: { next_before: null, first_message_id: 1 },
      },
    });
    history = scope.run(() => useCampaignHistory());
    await flushPromises();
    ConversationApi.getCampaignHistory.mockRejectedValueOnce(
      new Error('Offline')
    );
    chat.value.messages.push({ id: 2, created_at: 200 });
    await flushPromises();

    ConversationApi.getCampaignHistory.mockResolvedValueOnce({
      data: {
        payload: [{ id: 20, sent_at: 90, source_id: 'campaign-20' }],
        meta: { next_before: 20, first_message_id: 1 },
      },
    });
    chat.value = { ...chat.value, id: 2 };
    await flushPromises();
    expect(history.campaignHistoryError.value).toBe(false);

    ConversationApi.getCampaignHistory.mockResolvedValueOnce({
      data: {
        payload: [],
        meta: { next_before: null, first_message_id: 1 },
      },
    });
    await history.loadCampaignHistory();
    expect(ConversationApi.getCampaignHistory).toHaveBeenLastCalledWith(2, {
      before: 20,
      signal: expect.any(AbortSignal),
    });
  });
});
