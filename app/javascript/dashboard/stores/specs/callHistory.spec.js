import { setActivePinia, createPinia } from 'pinia';
import CallsAPI from 'dashboard/api/calls';
import { throwErrorMessage } from 'dashboard/store/utils/api';
import { useCallHistoryStore } from '../callHistory';

vi.mock('dashboard/api/calls', () => ({
  default: {
    get: vi.fn(),
  },
}));

vi.mock('dashboard/store/utils/api', () => ({
  throwErrorMessage: vi.fn(error => error),
}));

const createDeferred = () => {
  let resolve;
  const promise = new Promise(res => {
    resolve = res;
  });

  return { promise, resolve };
};

const buildResponse = (payload, meta) => ({ data: { payload, meta } });

describe('callHistory store', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    vi.clearAllMocks();
  });

  it('fetches calls and stores camelized records and meta', async () => {
    CallsAPI.get.mockResolvedValue(
      buildResponse(
        [{ id: 1, recording_url: 'rec.mp3', contact: { phone_number: '+1' } }],
        { count: 44, current_page: 1, total_pages: 2 }
      )
    );
    const store = useCallHistoryStore();

    await store.fetchCalls({ page: 1, status: 'no-answer' });

    expect(CallsAPI.get).toHaveBeenCalledWith({ page: 1, status: 'no-answer' });
    expect(store.records).toEqual([
      { id: 1, recordingUrl: 'rec.mp3', contact: { phoneNumber: '+1' } },
    ]);
    expect(store.meta).toEqual({ count: 44, currentPage: 1, totalPages: 2 });
    expect(store.uiFlags.isFetching).toBe(false);
  });

  it('drops a superseded response that resolves after the latest one', async () => {
    const firstRequest = createDeferred();
    const secondRequest = createDeferred();
    CallsAPI.get
      .mockImplementationOnce(() => firstRequest.promise)
      .mockImplementationOnce(() => secondRequest.promise);
    const store = useCallHistoryStore();

    const staleFetch = store.fetchCalls({ page: 1 });
    const currentFetch = store.fetchCalls({ page: 2 });

    secondRequest.resolve(
      buildResponse([{ id: 2 }], { count: 1, current_page: 2, total_pages: 2 })
    );
    await currentFetch;

    firstRequest.resolve(
      buildResponse([{ id: 1 }], { count: 99, current_page: 1, total_pages: 9 })
    );
    await staleFetch;

    expect(store.records).toEqual([{ id: 2 }]);
    expect(store.meta.count).toBe(1);
    expect(store.uiFlags.isFetching).toBe(false);
  });

  it('keeps fetching state when a superseded response resolves first', async () => {
    const firstRequest = createDeferred();
    const secondRequest = createDeferred();
    CallsAPI.get
      .mockImplementationOnce(() => firstRequest.promise)
      .mockImplementationOnce(() => secondRequest.promise);
    const store = useCallHistoryStore();

    const staleFetch = store.fetchCalls({ page: 1 });
    const currentFetch = store.fetchCalls({ page: 2 });

    firstRequest.resolve(
      buildResponse([{ id: 1 }], { count: 99, current_page: 1, total_pages: 9 })
    );
    await staleFetch;

    expect(store.records).toEqual([]);
    expect(store.uiFlags.isFetching).toBe(true);

    secondRequest.resolve(
      buildResponse([{ id: 2 }], { count: 1, current_page: 2, total_pages: 2 })
    );
    await currentFetch;

    expect(store.records).toEqual([{ id: 2 }]);
    expect(store.uiFlags.isFetching).toBe(false);
  });

  it('surfaces the error and resets fetching state on failure', async () => {
    const error = new Error('Request failed');
    CallsAPI.get.mockRejectedValue(error);
    const store = useCallHistoryStore();

    await store.fetchCalls();

    expect(throwErrorMessage).toHaveBeenCalledWith(error);
    expect(store.records).toEqual([]);
    expect(store.uiFlags.isFetching).toBe(false);
  });
});
