<script>
import { ref, computed, nextTick } from 'vue';
import { useKeyboardNavigableList } from 'dashboard/composables/useKeyboardNavigableList';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

export default {
  props: {
    items: {
      type: Array,
      default: () => [],
    },
    isLoading: {
      type: Boolean,
      default: false,
    },
    emptyPlaceholder: {
      type: String,
      default: '',
    },
    loadingPlaceholder: {
      type: String,
      default: '',
    },
    searchTerm: {
      type: String,
      default: '',
    },
  },
  setup(props) {
    const selectedIndex = ref(-1);
    const portalSearchSuggestionsRef = ref(null);
    const { highlightContent } = useMessageFormatter();
    const adjustScroll = () => {
      nextTick(() => {
        portalSearchSuggestionsRef.value.scrollTop = 102 * selectedIndex.value;
      });
    };

    const isSearchItemActive = index => {
      return index === selectedIndex.value
        ? 'bg-slate-25 dark:bg-slate-800'
        : 'bg-white dark:bg-slate-900';
    };

    useKeyboardNavigableList({
      items: computed(() => props.items),
      adjustScroll,
      selectedIndex,
    });

    return {
      selectedIndex,
      portalSearchSuggestionsRef,
      isSearchItemActive,
      highlightContent,
    };
  },

  computed: {
    showEmptyResults() {
      return !this.items.length && !this.isLoading;
    },
    shouldShowResults() {
      return this.items.length && !this.isLoading;
    },
  },

  methods: {
    generateArticleUrl(article) {
      return `/hc/${article.portal.slug}/articles/${article.slug}`;
    },
    prepareContent(content) {
      return this.highlightContent(
        content,
        this.searchTerm,
        'bg-slate-100 dark:bg-slate-700 font-semibold text-slate-600 dark:text-slate-200'
      );
    },
  },
};
</script>

<template>
  <div
    ref="portalSearchSuggestionsRef"
    class="p-5 mt-2 overflow-y-auto text-sm bg-white border border-solid rounded-lg shadow-xl hover:shadow-lg dark:bg-slate-900 max-h-96 scroll-py-2 text-slate-700 dark:text-slate-100 border-slate-50 dark:border-slate-800"
  >
    <div
      v-if="isLoading"
      class="text-sm font-medium text-slate-400 dark:text-slate-700"
    >
      {{ loadingPlaceholder }}
    </div>
    <ul
      v-if="shouldShowResults"
      class="flex flex-col gap-4 text-sm bg-white dark:bg-slate-900 text-slate-700 dark:text-slate-100"
      role="listbox"
    >
      <li
        v-for="(article, index) in items"
        :id="article.id"
        :key="article.id"
        class="flex items-center p-4 border border-solid rounded-lg cursor-pointer select-none group hover:bg-slate-25 dark:hover:bg-slate-800 border-slate-100 dark:border-slate-800"
        :class="isSearchItemActive(index)"
        role="option"
        tabindex="-1"
        @mouse-enter="onHover(index)"
        @mouse-leave="onHover(-1)"
      >
        <a
          class="flex flex-col gap-1 overflow-y-hidden"
          :href="generateArticleUrl(article)"
        >
          <span
            v-dompurify-html="prepareContent(article.title)"
            class="flex-auto w-full overflow-hidden text-base font-semibold leading-6 truncate text-ellipsis whitespace-nowrap"
          />
          <div
            v-dompurify-html="prepareContent(article.content)"
            class="overflow-hidden text-sm line-clamp-2 text-ellipsis whitespace-nowrap text-slate-600 dark:text-slate-300"
          />
        </a>
      </li>
    </ul>

    <div
      v-if="showEmptyResults"
      class="text-sm font-medium text-slate-400 dark:text-slate-700"
    >
      {{ emptyPlaceholder }}
    </div>
  </div>
</template>
