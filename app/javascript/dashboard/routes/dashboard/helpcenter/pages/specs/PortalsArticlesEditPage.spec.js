import { flushPromises, shallowMount } from '@vue/test-utils';
import { reactive, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import articlesAPI from 'dashboard/api/helpCenter/articles';
import PortalsArticlesEditPage from '../PortalsArticlesEditPage.vue';

vi.mock('vue-router', () => ({ useRoute: vi.fn(), useRouter: vi.fn() }));
vi.mock('vue-i18n', () => ({ useI18n: () => ({ t: key => key }) }));
vi.mock('dashboard/composables/store', () => ({
  useStore: vi.fn(),
  useMapGetter: vi.fn(),
}));
vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
  useTrack: vi.fn(),
}));
vi.mock('dashboard/api/helpCenter/articles', () => ({
  default: { getPreviewToken: vi.fn() },
}));
vi.mock(
  'dashboard/components-next/HelpCenter/Pages/ArticleEditorPage/ArticleEditor.vue',
  () => ({ default: { name: 'ArticleEditor', template: '<div />' } })
);

const makeArticle = id => ({
  id,
  slug: `article-${id}`,
  status: 'draft',
  category: { slug: 'general', locale: 'en' },
});

describe('PortalsArticlesEditPage signed previews', () => {
  let route;
  let dispatch;
  let open;
  let previewTab;
  let wrapper;

  beforeEach(() => {
    vi.stubGlobal('chatwootConfig', { hostURL: 'https://app.example.com' });
    route = reactive({ params: { articleSlug: '1', portalSlug: 'help' } });
    dispatch = vi.fn().mockResolvedValue({});
    useRoute.mockReturnValue(route);
    useRouter.mockReturnValue({ push: vi.fn() });
    useStore.mockReturnValue({ dispatch });
    useMapGetter.mockImplementation(key =>
      ref(key === 'articles/articleById' ? makeArticle : () => ({}))
    );
    articlesAPI.getPreviewToken.mockImplementation(({ id }) =>
      Promise.resolve({ data: { preview_token: `token-${id}` } })
    );
    previewTab = { location: { replace: vi.fn() }, close: vi.fn(), opener: {} };
    open = vi.spyOn(window, 'open').mockReturnValue(previewTab);
  });

  afterEach(() => {
    wrapper?.unmount();
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
    vi.useRealTimers();
  });

  it.each(['draft', 'archived'])(
    'fetches a fresh token on click for a %s article',
    async status => {
      useMapGetter.mockImplementation(key =>
        ref(
          key === 'articles/articleById'
            ? id => ({ ...makeArticle(id), status })
            : () => ({})
        )
      );
      wrapper = shallowMount(PortalsArticlesEditPage);
      await flushPromises();
      expect(dispatch).toHaveBeenCalledWith('articles/show', {
        id: '1',
        portalSlug: 'help',
      });
      expect(articlesAPI.getPreviewToken).not.toHaveBeenCalled();

      wrapper
        .findComponent({ name: 'ArticleEditor' })
        .vm.$emit('previewArticle');
      expect(open).toHaveBeenCalledWith('about:blank', '_blank');
      expect(previewTab.opener).toBeNull();
      await flushPromises();

      expect(articlesAPI.getPreviewToken).toHaveBeenCalledWith({
        id: '1',
        portalSlug: 'help',
      });
      expect(previewTab.location.replace).toHaveBeenCalledWith(
        'https://app.example.com/hc/help/articles/article-1?preview_token=token-1'
      );
    }
  );

  it('fetches a new token after the editor stays open for more than an hour', async () => {
    vi.useFakeTimers({ toFake: ['Date'] });
    articlesAPI.getPreviewToken
      .mockResolvedValueOnce({ data: { preview_token: 'first-token' } })
      .mockResolvedValueOnce({ data: { preview_token: 'fresh-token' } });
    wrapper = shallowMount(PortalsArticlesEditPage);
    await flushPromises();
    wrapper.findComponent({ name: 'ArticleEditor' }).vm.$emit('previewArticle');
    await flushPromises();

    vi.setSystemTime(new Date(Date.now() + 61 * 60 * 1000));
    wrapper.findComponent({ name: 'ArticleEditor' }).vm.$emit('previewArticle');
    await flushPromises();

    expect(articlesAPI.getPreviewToken).toHaveBeenCalledTimes(2);
    expect(previewTab.location.replace).toHaveBeenLastCalledWith(
      'https://app.example.com/hc/help/articles/article-1?preview_token=fresh-token'
    );
  });

  it('opens the tab before a slow request and preserves the clicked article after navigation', async () => {
    let resolveToken;
    articlesAPI.getPreviewToken.mockImplementationOnce(
      () =>
        new Promise(resolve => {
          resolveToken = resolve;
        })
    );
    wrapper = shallowMount(PortalsArticlesEditPage);
    wrapper.findComponent({ name: 'ArticleEditor' }).vm.$emit('previewArticle');

    expect(open).toHaveBeenCalledTimes(1);
    expect(previewTab.location.replace).not.toHaveBeenCalled();
    route.params.articleSlug = '2';
    await flushPromises();
    expect(dispatch).toHaveBeenLastCalledWith('articles/show', {
      id: '2',
      portalSlug: 'help',
    });
    resolveToken({ data: { preview_token: 'token-1' } });
    await flushPromises();

    expect(previewTab.location.replace).toHaveBeenCalledWith(
      'https://app.example.com/hc/help/articles/article-1?preview_token=token-1'
    );
    wrapper.findComponent({ name: 'ArticleEditor' }).vm.$emit('previewArticle');
    await flushPromises();
    expect(articlesAPI.getPreviewToken).toHaveBeenLastCalledWith({
      id: '2',
      portalSlug: 'help',
    });
    expect(previewTab.location.replace).toHaveBeenLastCalledWith(
      'https://app.example.com/hc/help/articles/article-2?preview_token=token-2'
    );
  });

  it('closes the blank tab on request failure and allows retrying', async () => {
    articlesAPI.getPreviewToken.mockRejectedValueOnce(new Error('Unavailable'));
    wrapper = shallowMount(PortalsArticlesEditPage);
    wrapper.findComponent({ name: 'ArticleEditor' }).vm.$emit('previewArticle');
    await flushPromises();

    expect(previewTab.close).toHaveBeenCalledOnce();
    expect(previewTab.location.replace).not.toHaveBeenCalled();
    expect(useAlert).toHaveBeenCalledWith(
      'HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.PREVIEW_ERROR'
    );
    const retryTab = { location: { replace: vi.fn() }, close: vi.fn() };
    open.mockReturnValueOnce(retryTab);
    wrapper.findComponent({ name: 'ArticleEditor' }).vm.$emit('previewArticle');
    await flushPromises();

    expect(retryTab.location.replace).toHaveBeenCalledWith(
      'https://app.example.com/hc/help/articles/article-1?preview_token=token-1'
    );
  });

  it('shows a popup warning without requesting a token when the tab is blocked', async () => {
    open.mockReturnValueOnce(null);
    wrapper = shallowMount(PortalsArticlesEditPage);
    wrapper.findComponent({ name: 'ArticleEditor' }).vm.$emit('previewArticle');
    await flushPromises();

    expect(articlesAPI.getPreviewToken).not.toHaveBeenCalled();
    expect(useAlert).toHaveBeenCalledWith(
      'HELP_CENTER.EDIT_ARTICLE_PAGE.HEADER.PREVIEW_POPUP_BLOCKED'
    );
  });

  it('opens published articles without requesting a preview token', async () => {
    useMapGetter.mockImplementation(key =>
      ref(
        key === 'articles/articleById'
          ? id => ({ ...makeArticle(id), status: 'published' })
          : () => ({})
      )
    );
    wrapper = shallowMount(PortalsArticlesEditPage);
    wrapper.findComponent({ name: 'ArticleEditor' }).vm.$emit('previewArticle');
    await flushPromises();

    expect(articlesAPI.getPreviewToken).not.toHaveBeenCalled();
    expect(previewTab.location.replace).toHaveBeenCalledWith(
      'https://app.example.com/hc/help/articles/article-1'
    );
  });
});
