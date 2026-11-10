import { reactive, ref } from 'vue';
import { createPinia, setActivePinia } from 'pinia';
import { flushPromises, shallowMount } from '@vue/test-utils';
import { useRoute, useRouter } from 'vue-router';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { usePolicy } from 'dashboard/composables/usePolicy';
import SearchAPI from 'dashboard/api/search';
import SearchView from '../SearchView.vue';

vi.mock('vue-router');
vi.mock('dashboard/composables/store.js');
vi.mock('dashboard/composables/useAccount');
vi.mock('dashboard/composables/usePolicy');
vi.mock('dashboard/composables', () => ({ useTrack: vi.fn() }));
vi.mock('dashboard/api/search');

describe('SearchView URL navigation', () => {
  let route;
  let wrapper;

  beforeEach(async () => {
    setActivePinia(createPinia());
    route = reactive({
      params: { accountId: '1', tab: 'messages' },
      query: { q: 'invoice' },
    });
    useRoute.mockReturnValue(route);
    useRouter.mockReturnValue({ replace: vi.fn() });
    useStore.mockReturnValue({ dispatch: vi.fn() });
    useMapGetter.mockReturnValue(
      ref({ accounts: [{ id: 1, permissions: ['administrator'] }] })
    );
    useAccount.mockReturnValue({ currentAccount: ref({ id: 1 }) });
    usePolicy.mockReturnValue({
      shouldShow: () => true,
      isFeatureFlagEnabled: () => true,
      checkPermissions: () => true,
    });
    SearchAPI.counts.mockResolvedValue({
      data: { payload: { counts: {} }, meta: {} },
    });
    ['contacts', 'conversations', 'messages', 'articles'].forEach(type => {
      SearchAPI[type].mockResolvedValue({
        data: { payload: { [type]: [] }, meta: { message_backend: 'like' } },
      });
    });
    wrapper = shallowMount(SearchView, {
      global: { stubs: { FluentIcon: true } },
    });
    await flushPromises();
  });

  afterEach(() => {
    wrapper.unmount();
  });

  it('loads a new URL tab and reuses its cached page when returning', async () => {
    expect(SearchAPI.messages).toHaveBeenCalledTimes(1);
    expect(SearchAPI.contacts).not.toHaveBeenCalled();

    route.params.tab = 'contacts';
    await flushPromises();

    expect(SearchAPI.contacts).toHaveBeenCalledWith(
      { q: 'invoice', page: 1, perPage: 15 },
      { signal: expect.any(AbortSignal) }
    );
    expect(SearchAPI.messages).toHaveBeenCalledTimes(1);

    route.params.tab = 'messages';
    await flushPromises();

    expect(SearchAPI.messages).toHaveBeenCalledTimes(1);
    expect(SearchAPI.counts).toHaveBeenCalledTimes(1);
  });

  it('starts a fresh search when the URL query changes', async () => {
    route.query.q = 'refund';
    await flushPromises();

    expect(SearchAPI.messages).toHaveBeenLastCalledWith(
      { q: 'refund', page: 1, perPage: 15 },
      { signal: expect.any(AbortSignal) }
    );
    expect(SearchAPI.counts).toHaveBeenCalledTimes(2);
  });
});
