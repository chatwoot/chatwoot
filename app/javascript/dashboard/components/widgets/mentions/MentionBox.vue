<template>
  <div v-if="items.length" ref="mentionsListContainer" class="mention--box">
    <ul class="vertical dropdown menu">
      <woot-dropdown-item
        v-for="(item, index) in items"
        :id="`mention-item-${index}`"
        :key="item.key"
        @mouseover="onHover(index)"
      >
        <woot-button
          size="small"
          class="text-truncate"
          :variant="index === selectedIndex ? 'smooth' : 'clear'"
          @click="onListItemSelection(index)"
        >
          <strong>{{ item.label }}</strong> - {{ item.description }}
        </woot-button>
      </woot-dropdown-item>
    </ul>
  </div>
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
  box-shadow: var(--shadow-medium);
  border-radius: var(--border-radius-normal);
  border-top: 1px solid var(--color-border);
  left: 0;
  bottom: 100%;
  max-height: 18rem;
  overflow: auto;
  padding: var(--space-small) var(--space-small) 0;
  position: absolute;
  width: 100%;
  z-index: 100;

  .dropdown-menu__item:last-child {
    padding-bottom: var(--space-smaller);
  }

  .active a {
    background: var(--w-500);
  }
}
</style>
