<template>
  <div role="dialog" class="emoji-dialog">
    <div class="emoji-list--wrap">
      <div class="emoji-search--wrap">
        <input
          ref="searchbar"
          v-model="search"
          type="text"
          class="emoji-search--input"
          :placeholder="$t('EMOJI.PLACEHOLDER')"
        />
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
            <fluent-icon icon="emoji" size="48" />
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
              <fluent-icon icon="search" size="16" />
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

<script>
import emojis from './emojisGroup.json';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
const SEARCH_KEY = 'Search';

export default {
  components: { FluentIcon },
  props: {
    onClick: {
      type: Function,
      default: () => {},
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
      this.$refs.searchbar.focus();
    },
  },
};
</script>
<style lang="scss">
/**
 * All the units used below are pixels due to variable name conflict in widget and dashboard
 **/
@import '~dashboard/assets/scss/variables';
@import '~dashboard/assets/scss/mixins';

$space-smaller: 4px;
$space-small: 8px;
$space-slab: 12px;
$space-normal: 16px;
$space-two: 20px;
$space-medium: 24px;
$space-large: 28px;
$space-larger: 32px;

$font-size-tiny: 12px;
$font-size-small: 14px;
$font-size-default: 16px;
$font-size-medium: 18px;

$color-bg: #ebf0f5;

$border-radius-normal: 5px;

.emoji-dialog {
  @include elegant-card;
  background: $color-white;
  border-radius: $space-small;
  box-sizing: content-box;
  height: 300px;
  position: absolute;
  right: 0;
  top: -95px;
  width: 320px;
  z-index: 1;

  &::before {
    @include arrow(bottom, $color-bg, $space-slab);
    bottom: -$space-slab;
    position: absolute;
    right: $space-two;
  }
}

.emoji-list--wrap {
  display: flex;
  flex-direction: column;
}

.emoji--item {
  background: transparent;
  border: 0;
  border-radius: $space-smaller;
  cursor: pointer;
  font-size: $font-size-medium;
  height: $space-medium;
  margin: 0;
  padding: 0 $space-smaller;

  &:hover {
    background: var(--s-75);
  }
}

.emoji--row {
  box-sizing: border-box;
  padding: $space-smaller;

  .emoji--item {
    height: 26px;
    line-height: 1.5;
    margin: $space-smaller;
    width: 26px;
  }
}

.emoji-search--wrap {
  margin: $space-small;
  position: sticky;
  top: $space-small;

  .emoji-search--input {
    background-color: $color-bg;
    border: 1px solid transparent;
    border-radius: $border-radius-normal;
    font-size: $font-size-small;
    height: $space-larger;
    margin: 0;
    padding: $space-small;
    width: 100%;

    &:focus {
      box-shadow: 0 0 0 1px $color-woot, 0 0 2px 3px $color-primary-light;
    }
  }
}

.empty-message {
  align-items: center;
  display: flex;
  flex-direction: column;
  height: 212px;
  justify-content: center;

  .emoji-icon {
    color: var(--s-200);
    margin-bottom: $space-small;
  }
  .empty-message--text {
    color: var(--s-200);
    font-size: $font-size-small;
    font-weight: 500;
  }
}

.emoji-item {
  height: 212px;
  overflow-y: auto;
}

.emoji-category--title {
  color: $color-heading;
  font-size: $font-size-small;
  font-weight: 500;
  line-height: 1.5;
  margin: 0;
  padding: $space-smaller $space-small;
  text-transform: capitalize;
}

.emoji-dialog--footer {
  background-color: $color-bg;
  bottom: 0;
  padding: 0 $space-smaller;
  position: sticky;

  ul {
    display: flex;
    list-style: none;
    margin: 0;
    overflow: auto;
    padding: $space-smaller 0;

    > li {
      align-items: center;
      cursor: pointer;
      display: flex;
      justify-content: center;
      padding: $space-smaller;
    }

    li .active {
      background: $color-white;
    }
    .emoji--item {
      align-items: center;
      display: flex;
      font-size: $font-size-small;

      &:hover {
        background: $color-bg;
      }
    }
  }
}
</style>
