<script>
import emojis from './emojisGroup.json';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import WootButton from 'dashboard/components/ui/WootButton.vue';
const SEARCH_KEY = 'Search';

export default {
  components: { FluentIcon, WootButton },
  props: {
    onClick: {
      type: Function,
      default: () => {},
    },
    showRemoveButton: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      selectedKey: 'Search',
      emojis,
      search: '',
    };
  },
  computed: {
    categories() {
      return [...this.emojis];
    },
    filterEmojisByCategory() {
      const selectedCategoryName = this.emojis.find(category =>
        category.name === this.selectedKey ? category.name : null
      );
      return selectedCategoryName?.emojis;
    },
    filterAllEmojisBySearch() {
      return this.emojis.map(category => {
        const allEmojis = category.emojis.filter(emoji =>
          emoji.slug.replaceAll('_', ' ').includes(this.search.toLowerCase())
        );
        return allEmojis.length > 0
          ? { ...category, emojis: allEmojis }
          : { ...category, emojis: [] };
      });
    },
    hasNoSearch() {
      return this.selectedKey !== SEARCH_KEY && this.search === '';
    },
    hasEmptySearchResult() {
      return this.filterAllEmojisBySearch.every(
        category => category.emojis.length === 0
      );
    },
  },
  watch: {
    search() {
      this.selectedKey = 'Search';
    },
    selectedKey() {
      return this.selectedKey === 'Search' ? this.focusSearchInput() : null;
    },
  },
  mounted() {
    this.focusSearchInput();
  },
  methods: {
    changeCategory(category) {
      this.search = '';
      this.$refs.emojiItem.scrollTo({ top: 0 });
      this.selectedKey = category;
    },
    getFirstEmojiByCategoryName(categoryName) {
      const categoryItem = this.emojis.find(category =>
        category.name === categoryName ? category : null
      );
      return categoryItem ? categoryItem.emojis[0].emoji : '';
    },
    focusSearchInput() {
      this.$nextTick(() => {
        this.$refs.searchbar.focus();
      });
    },
  },
};
</script>

<template>
  <div
    role="dialog"
    class="emoji-dialog bg-white shadow-lg dark:bg-slate-900 rounded-md border border-solid border-slate-75 dark:border-slate-800/50 box-content h-[300px] absolute right-0 -top-[95px] w-80 z-20"
  >
    <div class="flex flex-col">
      <div class="flex gap-2 emoji-search--wrap">
        <input
          ref="searchbar"
          v-model="search"
          type="text"
          class="emoji-search--input focus:box-shadow-blue dark:focus:box-shadow-dark !mb-0 !h-8 !text-sm"
          :placeholder="$t('EMOJI.PLACEHOLDER')"
        />
        <WootButton
          v-if="showRemoveButton"
          size="small"
          variant="smooth"
          class="dark:!bg-slate-800 dark:!hover:bg-slate-700"
          color-scheme="secondary"
          @click="onClick('')"
        >
          {{ $t('EMOJI.REMOVE') }}
        </WootButton>
      </div>
      <div v-if="hasNoSearch" ref="emojiItem" class="emoji-item">
        <h5 class="emoji-category--title">
          {{ selectedKey }}
        </h5>
        <div class="emoji--row">
          <button
            v-for="item in filterEmojisByCategory"
            :key="item.slug"
            v-dompurify-html="item.emoji"
            class="emoji--item"
            track-by="$index"
            @click="onClick(item.emoji)"
          />
        </div>
      </div>
      <div v-else ref="emojiItem" class="emoji-item">
        <div v-for="category in filterAllEmojisBySearch" :key="category.slug">
          <h5 v-if="category.emojis.length > 0" class="emoji-category--title">
            {{ category.name }}
          </h5>
          <div v-if="category.emojis.length > 0" class="emoji--row">
            <button
              v-for="item in category.emojis"
              :key="item.slug"
              v-dompurify-html="item.emoji"
              class="emoji--item"
              track-by="$index"
              @click="onClick(item.emoji)"
            />
          </div>
        </div>
        <div v-if="hasEmptySearchResult" class="empty-message">
          <div class="emoji-icon">
            <FluentIcon icon="emoji" size="48" />
          </div>
          <span class="empty-message--text">
            {{ $t('EMOJI.NOT_FOUND') }}
          </span>
        </div>
      </div>

      <div class="emoji-dialog--footer" role="menu">
        <ul>
          <li>
            <button
              class="emoji--item"
              :class="{ active: selectedKey === 'Search' }"
              @click="changeCategory('Search')"
            >
              <FluentIcon
                icon="search"
                size="16"
                class="text-slate-700 dark:text-slate-100"
              />
            </button>
          </li>
          <li
            v-for="category in categories"
            :key="category.slug"
            @click="changeCategory(category.name)"
          >
            <button
              v-dompurify-html="getFirstEmojiByCategoryName(category.name)"
              class="emoji--item"
              :class="{ active: selectedKey === category.name }"
              @click="changeCategory(category.name)"
            />
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<style scoped>
@tailwind components;

@layer components {
  .box-shadow-blue {
    box-shadow:
      0 0 0 1px #1f93ff,
      0 0 1px 2px #c7e3ff;
  }

  .box-shadow-dark {
    box-shadow:
      0 0 0 1px #212222,
      0 0 1px 2px #4c5155;
  }
}
</style>

<style lang="scss">
@import 'dashboard/assets/scss/mixins';

.emoji-dialog {
  &::before {
    $space-slab: 12px;

    @media (prefers-color-scheme: dark) {
      $color-bg-dark: #26292b;
      @include arrow(bottom, $color-bg-dark, $space-slab);
    }

    @media (prefers-color-scheme: light) {
      $color-bg: #ebf0f5;
      @include arrow(bottom, $color-bg, $space-slab);
    }

    @apply -bottom-3 absolute right-5;
  }
}

.emoji--item {
  @apply bg-transparent border-0 rounded cursor-pointer text-lg h-6 m-0 py-0 px-1 hover:bg-slate-75 dark:hover:bg-slate-800;
}

.emoji--row {
  @apply box-border p-1;

  .emoji--item {
    @apply h-[26px] w-[26px] leading-normal m-1;
  }
}

.emoji-search--wrap {
  @apply m-2 sticky top-2;

  .emoji-search--input {
    @apply text-sm focus-visible:border-transparent text-slate-800 dark:text-slate-100 h-8 m-0 p-2 w-full rounded-md bg-slate-50 dark:bg-slate-800 border border-solid border-transparent dark:border-slate-800/50;
  }
}

.empty-message {
  @apply items-center flex flex-col h-[212px] justify-center;

  .emoji-icon {
    @apply text-slate-200 dark:text-slate-200 mb-2;
  }

  .empty-message--text {
    @apply text-slate-200 dark:text-slate-200 text-sm font-medium;
  }
}

.emoji-item {
  @apply h-[212px] overflow-y-auto;
}

.emoji-category--title {
  @apply text-slate-800 text-sm dark:text-slate-100 font-medium leading-normal m-0 py-1 px-2 capitalize;
}

.emoji-dialog--footer {
  @apply relative w-[322px] -left-px rtl:left-[unset] rtl:-right-px bottom-0 py-0 rounded-b-md border-b border-solid border-slate-75 dark:border-slate-800/50 px-1 bg-slate-75 dark:bg-slate-800;

  ul {
    @apply flex relative left-[2px] rtl:left-[unset] rtl:right-[2px] list-none m-0 overflow-auto py-1 px-0;

    > li {
      @apply items-center cursor-pointer flex justify-center p-1;
    }

    li .active {
      @apply bg-white dark:bg-slate-900;
    }

    .emoji--item {
      @apply items-center flex text-sm;

      &:hover {
        @apply bg-slate-75 dark:bg-slate-900;
      }
    }
  }
}
</style>
