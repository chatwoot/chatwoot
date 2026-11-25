import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useUISettings } from 'dashboard/composables/useUISettings';

// The order of the help center's Articles tab (#811), kept in the user's UI settings in the format
// the API takes: a field, prefixed with `-` for descending. A category ignores it and keeps the
// manual order, which is the one the public portal shows: the API orders a category by position
// whatever it is asked, so with a category on screen the order is neither sent nor offered.
const ARTICLE_SORT_FIELDS = Object.freeze([
  'updated_at',
  'created_at',
  'title',
  'views',
]);

const SETTING_KEY = 'help_center_articles_sort_by';
const DEFAULT_SORT = '-updated_at';
const SORT_PATTERN = new RegExp(`^-?(${ARTICLE_SORT_FIELDS.join('|')})$`);

export function useArticleListSort() {
  const route = useRoute();
  const { uiSettings, updateUISettings } = useUISettings();

  const appliesHere = computed(() => !route.params.categorySlug);

  // A value the API would turn down (an older client, a hand-edited setting) falls back to the
  // default here, so the list still loads.
  const sort = computed(() => {
    const saved = uiSettings.value?.[SETTING_KEY];
    return SORT_PATTERN.test(saved) ? saved : DEFAULT_SORT;
  });
  const sortField = computed(() => sort.value.replace(/^-/, ''));
  const sortOrder = computed(() => (sort.value.startsWith('-') ? '-' : ''));

  const setSort = ({ field, order }) => {
    updateUISettings({ [SETTING_KEY]: `${order}${field}` });
  };

  return { appliesHere, sort, sortField, sortOrder, setSort };
}
