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

.emoji-dialog {
  @include elegant-card;
  background: $color-white;
  border-radius: 8px;
  box-sizing: content-box;
  position: absolute;
  right: 0;
  top: -220px;
  width: 320px;

  &::before {
    @include arrow(bottom, $color-white, 12px);
    bottom: -12px;
    position: absolute;
    right: 20px;
  }

  .emoji--item {
    cursor: pointer;
    background: transparent;
    border: 0;
    font-size: 18px;
    font-size: 18px;
    margin: 0;
    padding: 0;
  }

  .emoji--row {
    box-sizing: border-box;
    height: 180px;
    overflow-y: auto;
    padding: 4px 16px;

    .emoji--item {
      float: left;
      margin: 4px;
      line-height: 1.5;
    }
  }

  .emoji-category--title {
    color: $color-heading;
    font-size: 14px;
    font-weight: 500;
    line-height: 1.5;
    margin: 0;
    text-transform: capitalize;
  }
}

.emoji-dialog--header {
  background-color: $color-body;
  border-top-left-radius: 8px;
  border-top-right-radius: 8px;
  padding: 0 4px;

  ul {
    display: flex;
    list-style: none;
    margin: 0;
    padding: 4px 0 0;

    > li {
      align-items: center;
      cursor: pointer;
      display: flex;
      height: 24px;
      justify-content: center;
      padding: 4px 8px;
    }

    > .active {
      background: $color-white;
      border-top-left-radius: 4px;
      border-top-right-radius: 4px;
    }
  }
}
</style>
