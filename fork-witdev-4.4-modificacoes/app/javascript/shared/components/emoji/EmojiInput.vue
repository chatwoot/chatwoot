<script>
import emojis from './emojisGroup.json';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
const SEARCH_KEY = 'Search';

export default {
  components: { FluentIcon, NextButton },
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
    class="emoji-dialog bg-n-background shadow-lg rounded-md outline outline-1 outline-n-weak box-content h-[18.75rem] absolute right-0 -top-[95px] w-80 z-20"
  >
    <div class="flex flex-col">
      <div class="flex gap-2 m-2 sticky top-2">
        <input
          ref="searchbar"
          v-model="search"
          type="text"
          class="focus:box-shadow-blue dark:focus:box-shadow-dark !mb-0 !h-8 !text-sm"
          :placeholder="$t('EMOJI.PLACEHOLDER')"
        />
        <NextButton
          v-if="showRemoveButton"
          faded
          sm
          slate
          class="flex-shrink-0"
          :label="$t('EMOJI.REMOVE')"
          @click="onClick('')"
        />
      </div>
      <div v-if="hasNoSearch" ref="emojiItem" class="emoji-item">
        <h5
          class="text-sm text-n-slate-12 font-medium leading-normal m-0 py-1 px-2 capitalize"
        >
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
          <h5
            v-if="category.emojis.length > 0"
            class="text-sm text-n-slate-12 font-medium leading-normal m-0 py-1 px-2 capitalize"
          >
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
        <div
          v-if="hasEmptySearchResult"
          class="items-center flex flex-col h-[13.25rem] justify-center"
        >
          <div class="text-n-slate-11 mb-2">
            <FluentIcon icon="emoji" size="48" />
          </div>
          <span class="text-n-slate-11 text-sm font-medium">
            {{ $t('EMOJI.NOT_FOUND') }}
          </span>
        </div>
      </div>

      <div
        class="emoji-dialog--footer relative w-full py-0 rounded-b-[0.34rem] px-1 bg-n-slate-3"
        role="menu"
      >
        <ul
          class="flex relative left-[2px] rtl:left-[unset] rtl:right-[2px] list-none m-0 overflow-auto py-1 px-0"
        >
          <li>
            <button
              class="emoji--item"
              :class="{ active: selectedKey === 'Search' }"
              @click="changeCategory('Search')"
            >
              <FluentIcon icon="search" size="16" class="text-n-slate-11" />
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
  @apply bg-transparent border-0 rounded cursor-pointer text-lg h-6 m-0 py-0 px-1 hover:bg-n-slate-4;
}

.emoji--row {
  @apply box-border p-1;

  .emoji--item {
    @apply h-[1.625rem] w-[1.625rem] leading-normal m-1;
  }
}

.emoji-item {
  @apply h-[13.25rem] overflow-y-auto;
}

.emoji-dialog--footer {
  ul {
    > li {
      @apply items-center cursor-pointer flex justify-center p-1;
    }

    li .active {
      @apply bg-n-background;
    }

    .emoji--item {
      @apply items-center flex text-sm;

      &:hover {
        @apply bg-n-slate-2;
      }
    }
  }
}
</style>
