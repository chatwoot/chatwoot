import { flushPromises, shallowMount } from '@vue/test-utils';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import PublicArticleSearch from '../components/PublicArticleSearch.vue';
import ArticlesAPI from '../api/article';

vi.mock('../api/article', () => ({
  default: {
    searchArticles: vi.fn(),
  },
}));

describe('PublicArticleSearch', () => {
  let originalPortalConfig;
  const SearchSuggestionsStub = {
    name: 'SearchSuggestions',
    template: '<div />',
    props: ['searchTerm'],
  };

  beforeEach(() => {
    vi.useFakeTimers();
    originalPortalConfig = window.portalConfig;
    window.portalConfig = {
      portalSlug: 'test-portal',
      localeCode: 'en',
      searchTranslations: {},
    };
  });

  afterEach(() => {
    vi.clearAllMocks();
    vi.useRealTimers();
    window.portalConfig = originalPortalConfig;
  });

  const buildWrapper = () =>
    shallowMount(PublicArticleSearch, {
      global: {
        directives: {
          onClickaway: () => {},
        },
        stubs: {
          SearchSuggestions: SearchSuggestionsStub,
          PublicSearchInput: true,
        },
      },
    });

  it('does not fetch or show suggestions for whitespace-only search terms', async () => {
    const wrapper = buildWrapper();
    wrapper.vm.searchResults = [{ id: 1 }];
    wrapper.vm.showSearchBox = true;

    wrapper.vm.onUpdateSearchTerm('   ');
    await wrapper.vm.$nextTick();
    vi.runAllTimers();
    await flushPromises();

    expect(ArticlesAPI.searchArticles).not.toHaveBeenCalled();
    expect(wrapper.vm.searchResults).toEqual([]);
    expect(wrapper.vm.shouldShowSearchBox).toBe(false);
    expect(wrapper.vm.isLoading).toBe(false);
  });

  it('trims the search term before requesting articles', async () => {
    ArticlesAPI.searchArticles.mockResolvedValue({ data: { payload: [] } });
    const wrapper = buildWrapper();

    wrapper.vm.onUpdateSearchTerm('  chatwoot  ');
    vi.runAllTimers();
    await flushPromises();

    expect(ArticlesAPI.searchArticles).toHaveBeenCalledWith(
      'test-portal',
      'en',
      'chatwoot'
    );
  });

  it('passes the trimmed search term to suggestions for highlighting', async () => {
    const wrapper = buildWrapper();

    wrapper.vm.onUpdateSearchTerm('  chatwoot  ');
    await wrapper.vm.$nextTick();

    expect(
      wrapper.findComponent(SearchSuggestionsStub).props('searchTerm')
    ).toBe('chatwoot');
  });
});
