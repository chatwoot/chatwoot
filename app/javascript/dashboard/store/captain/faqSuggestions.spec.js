import CaptainFaqSuggestionsAPI from 'dashboard/api/captain/faqSuggestions';
import faqSuggestions from './faqSuggestions';

vi.mock('dashboard/api/captain/faqSuggestions', () => ({
  default: {
    get: vi.fn(),
    approve: vi.fn(),
    dismiss: vi.fn(),
  },
}));

const deferred = () => {
  let resolve;
  const promise = new Promise(resolvePromise => {
    resolve = resolvePromise;
  });
  return { promise, resolve };
};

describe('captainFaqSuggestions', () => {
  it('keeps the latest assistant count when requests finish in the wrong order', async () => {
    const firstRequest = deferred();
    const secondRequest = deferred();
    CaptainFaqSuggestionsAPI.get
      .mockReturnValueOnce(firstRequest.promise)
      .mockReturnValueOnce(secondRequest.promise);
    const commit = vi.fn();

    const firstAction = faqSuggestions.actions.fetchOpenCount({ commit }, 1);
    const secondAction = faqSuggestions.actions.fetchOpenCount({ commit }, 2);

    secondRequest.resolve({ data: { meta: { total_count: 4 } } });
    await secondAction;
    firstRequest.resolve({ data: { meta: { total_count: 9 } } });
    await firstAction;

    expect(CaptainFaqSuggestionsAPI.get).toHaveBeenNthCalledWith(1, {
      assistantId: 1,
      page: 1,
    });
    expect(CaptainFaqSuggestionsAPI.get).toHaveBeenNthCalledWith(2, {
      assistantId: 2,
      page: 1,
    });
    expect(commit).toHaveBeenLastCalledWith('SET_OPEN_COUNT', 4);
  });
});
