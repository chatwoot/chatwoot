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
    const { highlightContent, getPlainText } = useMessageFormatter();
    const adjustScroll = () => {
      nextTick(() => {
        portalSearchSuggestionsRef.value.scrollTop = 102 * selectedIndex.value;
      });
    };

    const isSearchItemActive = index => {
      return index === selectedIndex.value ? 'bg-n-portal-soft' : '';
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
      getPlainText,
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
    prepareContent(content) {
      return this.highlightContent(
        content,
        this.searchTerm,
        'bg-n-portal-soft text-n-portal font-semibold rounded-sm px-1'
      );
    },
  },
};
</script>

<template>
  <div
    ref="portalSearchSuggestionsRef"
    class="mt-2 overflow-y-auto bg-white dark:bg-n-slate-2 border border-solid border-n-weak rounded-xl shadow-2xl max-h-96 p-2"
  >
    <div v-if="isLoading" class="px-3 py-6 text-sm text-n-slate-11 text-center">
      {{ loadingPlaceholder }}
    </div>
    <ul v-if="shouldShowResults" class="flex flex-col gap-0.5" role="listbox">
      <li
        v-for="(article, index) in items"
        :id="article.id"
        :key="article.id"
        class="rounded-md cursor-pointer select-none group transition-colors hover:bg-n-alpha-2"
        :class="isSearchItemActive(index)"
        role="option"
        tabindex="-1"
      >
        <a
          class="flex items-start gap-3 px-3 py-2.5 overflow-hidden"
          :href="article.link"
        >
          <span
            class="i-lucide-file-text size-4 mt-0.5 flex-shrink-0 text-n-slate-10 group-hover:text-n-slate-11"
            aria-hidden="true"
          />
          <span class="min-w-0 flex-1 flex flex-col gap-1">
            <span
              v-dompurify-html="prepareContent(getPlainText(article.title))"
              class="block text-base font-520 text-n-slate-12 truncate"
            />
            <span
              v-dompurify-html="prepareContent(article.content)"
              class="block text-sm text-n-slate-11 line-clamp-1"
            />
          </span>
        </a>
      </li>
    </ul>

    <div
      v-if="showEmptyResults"
      class="px-3 py-6 text-sm text-n-slate-11 text-center"
    >
      {{ emptyPlaceholder }}
    </div>
  </div>
</template>
