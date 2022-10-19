<template>
  <div role="dialog" class="emoji-dialog">
    <header class="emoji-dialog--header" role="menu">
      <ul>
        <li
          v-for="category in Object.keys(emojis)"
          :key="category"
          @click="changeCategory(category)"
        >
          <button
            v-dompurify-html="emojis[category][0]"
            class="emoji--item"
            :class="{ active: selectedKey === category }"
            @click="changeCategory(category)"
          />
        </li>
      </ul>
    </header>
    <h5 class="emoji-category--title">
      {{ selectedKey }}
    </h5>
    <div class="emoji--row">
      <button
        v-for="emoji in emojis[selectedKey]"
        :key="emoji"
        v-dompurify-html="emoji"
        class="emoji--item"
        track-by="$index"
        @click="onClick(emoji)"
      />
    </div>
  </div>
</template>

<script>
import emojis from './emojis.json';

export default {
  props: {
    onClick: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return {
      selectedKey: 'Smileys & Emotion',
      emojis,
    };
  },
  methods: {
    changeCategory(category) {
      this.selectedKey = category;
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

$font-size-tiny: 12px;
$font-size-small: 14px;
$font-size-default: 16px;
$font-size-medium: 18px;

$color-bg: #ebf0f5;

.emoji-dialog {
  @include elegant-card;
  background: $color-white;
  border-radius: $space-small;
  box-sizing: content-box;
  position: absolute;
  right: 0;
  top: -220px;
  width: 332px;
  z-index: 1;

  &::before {
    @include arrow(bottom, $color-white, $space-slab);
    bottom: -$space-slab;
    position: absolute;
    right: $space-two;
  }

  .emoji--item {
    cursor: pointer;
    background: transparent;
    border: 0;
    font-size: $font-size-medium;
    height: $space-medium;
    border-radius: $space-smaller;
    margin: 0;
    padding: 0 $space-smaller;

    &:hover {
      background: $color-bg;
    }
  }

  .emoji--row {
    display: flex;
    box-sizing: border-box;
    height: 200px;
    overflow-y: auto;
    padding: $space-smaller;
    flex-wrap: wrap;

    .emoji--item {
      margin: $space-smaller;
      line-height: 1.5;
    }
  }
}

.emoji-category--title {
  color: $color-heading;
  font-size: $font-size-small;
  font-weight: 500;
  line-height: 1.5;
  margin: 0;
  padding: $space-smaller $space-small;
  margin-top: $space-smaller;
  text-transform: capitalize;
}

.emoji-dialog--header {
  background-color: $color-bg;
  border-top-left-radius: $space-small;
  border-top-right-radius: $space-small;
  padding: 0 $space-smaller;

  ul {
    display: flex;
    list-style: none;
    overflow: auto;
    margin: 0;
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
      font-size: $font-size-small;

      &:hover {
        background: $color-bg;
      }
    }
  }
}
</style>
