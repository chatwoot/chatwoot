<template>
  <div role="dialog" class="emoji-dialog">
    <header class="emoji-dialog--header" role="menu">
      <ul>
        <li
          v-for="category in Object.keys(emojis)"
          :key="category"
          :class="{ active: selectedKey === category }"
          @click="changeCategory(category)"
        >
          <button
            class="emoji--item"
            @click="changeCategory(category)"
            v-html="emojis[category][0]"
          />
        </li>
      </ul>
    </header>
    <div class="emoji--row">
      <h5 class="emoji-category--title">
        {{ selectedKey }}
      </h5>
      <button
        v-for="emoji in emojis[selectedKey]"
        :key="emoji"
        class="emoji--item"
        track-by="$index"
        @click="onClick(emoji)"
        v-html="emoji"
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
$space-one: 10px;
$space-slab: 12px;
$space-normal: 16px;
$space-two: 20px;
$space-medium: 24px;

$font-size-small: 14px;
$font-size-default: 16px;
$font-size-medium: 18px;

.emoji-dialog {
  @include elegant-card;
  background: $color-white;
  border-radius: $space-small;
  box-sizing: content-box;
  position: absolute;
  right: 0;
  top: -22 * $space-one;
  width: 32 * $space-one;

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
    margin: 0;
    padding: 0;
  }

  .emoji--row {
    box-sizing: border-box;
    height: $space-one * 18;
    overflow-y: auto;
    padding: $space-smaller $space-normal;

    .emoji--item {
      float: left;
      margin: $space-smaller;
      line-height: 1.5;
    }
  }

  .emoji-category--title {
    color: $color-heading;
    font-size: $font-size-small;
    font-weight: 500;
    line-height: 1.5;
    margin: 0;
    text-transform: capitalize;
  }
}

.emoji-dialog--header {
  background-color: $color-body;
  border-top-left-radius: $space-small;
  border-top-right-radius: $space-small;
  padding: 0 $space-smaller;

  ul {
    display: flex;
    list-style: none;
    margin: 0;
    padding: $space-smaller 0 0;

    > li {
      align-items: center;
      cursor: pointer;
      display: flex;
      height: 2.4 * $space-one;
      justify-content: center;
      padding: $space-smaller $space-small;
    }

    > .active {
      background: $color-white;
      border-top-left-radius: $space-smaller;
      border-top-right-radius: $space-smaller;
    }
  }
}
</style>
