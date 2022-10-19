<template>
  <div
    class="shadow-md bg-white mt-2 max-h-72 scroll-py-2 p-4 rounded overflow-y-auto text-sm text-slate-700"
  >
    <div v-if="isLoading" class="font-medium text-sm text-slate-400">
      {{ loadingPlaceholder }}
    </div>
    <h3 v-if="shouldShowResults" class="font-medium text-sm text-slate-400">
      {{ resultsTitle }}
    </h3>
    <ul
      v-if="shouldShowResults"
      class="bg-white mt-2 max-h-72 scroll-py-2 overflow-y-auto text-sm text-slate-700"
      role="listbox"
    >
      <li
        v-for="(article, index) in items"
        :id="article.id"
        :key="article.id"
        class="group flex cursor-default select-none items-center rounded-md p-2 mb-1"
        :class="{ 'bg-slate-25': index === selectedIndex }"
        role="option"
        tabindex="-1"
        @mouseover="onHover(index)"
      >
        <a
          :href="generateArticleUrl(article)"
          class="flex-auto truncate text-base font-medium leading-6 w-full hover:underline"
        >
          {{ article.title }}
        </a>
      </li>
    </ul>

    <div v-if="showEmptyResults" class="font-medium text-sm text-slate-400">
      {{ emptyPlaceholder }}
    </div>
  </div>
</template>

<script>
import mentionSelectionKeyboardMixin from 'dashboard/components/widgets/mentions/mentionSelectionKeyboardMixin.js';

export default {
  mixins: [mentionSelectionKeyboardMixin],
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
    searchPlaceholder: {
      type: String,
      default: '',
    },
    loadingPlaceholder: {
      type: String,
      default: '',
    },
    resultsTitle: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      selectedIndex: 0,
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
      return `/hc/${article.portal.slug}/${article.category.locale}/${article.category.slug}/${article.id}`;
    },
    handleKeyboardEvent(e) {
      this.processKeyDownEvent(e);
      this.$el.scrollTop = 40 * this.selectedIndex;
    },
    onHover(index) {
      this.selectedIndex = index;
    },
    onSelect() {
      window.location = this.generateArticleUrl(this.items[this.selectedIndex]);
    },
  },
};
</script>
