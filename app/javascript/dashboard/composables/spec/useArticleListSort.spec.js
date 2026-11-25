import { ref } from 'vue';
import { useArticleListSort } from 'dashboard/composables/useArticleListSort';

const mockDispatch = vi.fn();
const uiSettings = ref({});
const route = { params: {} };

vi.mock('vue-router', () => ({ useRoute: () => route }));

vi.mock('dashboard/composables/store', () => ({
  useStoreGetters: () => ({ getUISettings: uiSettings }),
  useStore: () => ({ dispatch: mockDispatch }),
}));

describe('useArticleListSort', () => {
  beforeEach(() => {
    mockDispatch.mockClear();
    uiSettings.value = { editor_message_key: 'enter' };
    route.params = { portalSlug: 'docs', locale: 'en' };
  });

  it('starts from the last updated first when nothing was chosen', () => {
    const { sort, sortField, sortOrder } = useArticleListSort();

    expect(sort.value).toBe('-updated_at');
    expect(sortField.value).toBe('updated_at');
    expect(sortOrder.value).toBe('-');
  });

  it('reads the order the user chose', () => {
    uiSettings.value.help_center_articles_sort_by = 'title';
    const { sort, sortField, sortOrder } = useArticleListSort();

    expect(sort.value).toBe('title');
    expect(sortField.value).toBe('title');
    expect(sortOrder.value).toBe('');
  });

  // The API turns these down, so sending one would leave the tab without articles.
  it.each(['position', '-', '--views', 'title desc', 42, null])(
    'falls back to the default for a saved value the API does not take (%s)',
    value => {
      uiSettings.value.help_center_articles_sort_by = value;

      expect(useArticleListSort().sort.value).toBe('-updated_at');
    }
  );

  it('applies to the Articles tab', () => {
    expect(useArticleListSort().appliesHere.value).toBe(true);
  });

  // The API orders a category by position whatever it is asked, so a menu there would do nothing.
  it('does not apply once a category is on screen', () => {
    route.params.categorySlug = 'billing';

    expect(useArticleListSort().appliesHere.value).toBe(false);
  });

  it('saves the choice next to the other UI settings', () => {
    useArticleListSort().setSort({ field: 'created_at', order: '-' });

    expect(mockDispatch).toHaveBeenCalledWith('updateUISettings', {
      uiSettings: {
        editor_message_key: 'enter',
        help_center_articles_sort_by: '-created_at',
      },
    });
  });
});
