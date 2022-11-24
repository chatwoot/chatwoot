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
      <div v-if="hasNoSearch" class="emoji-item">
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
      <div v-else class="emoji-item">
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
      return this.emojis.map(category => category);
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
          emoji.name.includes(this.search)
        );
        return allEmojis.length > 0
          ? { ...category, emojis: allEmojis }
          : { ...category, emojis: [] };
      });
    },
    hasNoSearch() {
      return this.selectedKey !== 'Search' && this.search === '';
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
      this.$nextTick(() => {
        this.$refs.searchbar.focus();
      });
    },
  },
  mounted() {
    this.$refs.searchbar.focus();
  },
  methods: {
    changeCategory(category) {
      this.search = '';
      this.selectedKey = category;
    },
    getFirstEmojiByCategoryName(categoryName) {
      const categoryItem = this.emojis.find(category =>
        category.name === categoryName ? category : null
      );
      return categoryItem ? categoryItem.emojis[0].emoji : '';
    },
  },
};
</script>
<style lang="scss" scoped>
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
$color-text-light: #c9d7e3;

.emoji-dialog {
  @include elegant-card;
  background: $color-white;
  border-radius: $space-small;
  box-sizing: content-box;
  height: 300px;
  overflow-y: hidden;
  position: absolute;
  right: 0;
  top: -220px;
  width: 320px;
  z-index: 1;
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
      background: $color-bg;
    }
  }

  .emoji--row {
    box-sizing: border-box;
    padding: $space-smaller;

    .emoji--item {
      line-height: 1.5;
      margin: $space-smaller;
    }
  }
}

.emoji-search--wrap {
  background-color: $color-white;
  margin: $space-small;
  position: sticky;
  top: $space-small;

  .emoji-search--input {
    background-color: $color-bg;
    border: 1px solid transparent;
    border-radius: 5px;
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
    color: $color-text-light;
    margin-bottom: $space-small;
  }
  .empty-message--text {
    color: $color-text-light;
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
