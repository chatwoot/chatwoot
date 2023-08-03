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
          class="canned-item__button"
          :variant="index === selectedIndex ? '' : 'clear'"
          :class="{ active: index === selectedIndex }"
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
    selectedIndex() {
      const container = this.$refs.mentionsListContainer;
      const item = container.querySelector(
        `#mention-item-${this.selectedIndex}`
      );
      if (item) {
        const itemTop = item.offsetTop;
        const itemBottom = itemTop + item.offsetHeight;
        const containerTop = container.scrollTop;
        const containerBottom = containerTop + container.offsetHeight;
        if (itemTop < containerTop) {
          container.scrollTop = itemTop;
        } else if (itemBottom + 34 > containerBottom) {
          container.scrollTop = itemBottom - container.offsetHeight + 34;
        }
      }
    },
  },
  methods: {
    handleKeyboardEvent(e) {
      this.processKeyDownEvent(e);
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
  @apply bg-white dark:bg-slate-700 rounded-md overflow-auto absolute w-full z-[100] pt-2 px-2 pb-0 shadow-md left-0 bottom-full max-h-[9.75rem] border-t border-solid border-slate-75 dark:border-slate-800;

  .dropdown-menu__item:last-child {
    @apply pb-1;
  }

  .active {
    @apply text-white dark:text-white;

    &:hover {
      @apply bg-woot-700 dark:bg-woot-700;
    }
  }

  .button {
    @apply transition-none h-8 leading-[1.4];
  }
}

.canned-item__button::v-deep .button__content {
  @apply overflow-hidden text-ellipsis whitespace-nowrap;
}
</style>
