<template>
  <ul
    v-if="items.length"
    class="vertical dropdown menu mention--box"
    :style="{ top: getTopPadding() + 'rem' }"
  >
    <li
      v-for="(item, index) in items"
      :id="`mention-item-${index}`"
      :key="item.key"
      :class="{ active: index === selectedIndex }"
      @click="onListItemSelection(index)"
      @mouseover="onHover(index)"
    >
      <a class="text-truncate">
        <strong>{{ item.label }}</strong> - {{ item.description }}
      </a>
    </li>
  </ul>
</template>

<script>
import mentionSelectionKeyboardMixin from './mentionSelectionKeyboardMixin';
export default {
  mixins: [mentionSelectionKeyboardMixin],
  props: {
    items: {
      type: Array,
      default: () => {},
    },
  },
  data() {
    return {
      selectedIndex: 0,
    };
  },
  watch: {
    items(newItems) {
      if (newItems.length < this.selectedIndex + 1) {
        this.selectedIndex = 0;
      }
    },
  },
  methods: {
    getTopPadding() {
      if (this.items.length <= 4) {
        return -(this.items.length * 2.9 + 1.7);
      }
      return -14;
    },
    handleKeyboardEvent(e) {
      this.processKeyDownEvent(e);
      this.$el.scrollTop = 29 * this.selectedIndex;
    },
    onHover(index) {
      this.selectedIndex = index;
    },
    onListItemSelection(index) {
      this.selectedIndex = index;
      this.onSelect();
    },
    onSelect() {
      this.$emit('mention-select', this.items[this.selectedIndex]);
    },
  },
};
</script>

<style scoped lang="scss">
.mention--box {
  background: var(--white);
  border-bottom: var(--space-small) solid var(--white);
  border-top: 1px solid var(--color-border);
  left: 0;
  max-height: 14rem;
  overflow: auto;
  padding-top: var(--space-small);
  position: absolute;
  width: 100%;
  z-index: 100;

  .active a {
    background: var(--w-500);
  }
}
</style>
