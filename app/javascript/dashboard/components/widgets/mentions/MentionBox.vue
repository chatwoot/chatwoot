<template>
  <div
    ref="mentionsListContainer"
    class="bg-white dark:bg-slate-800 rounded-md overflow-auto absolute w-full z-20 pb-0 shadow-md left-0 bottom-full max-h-[9.75rem] border border-solid border-slate-100 dark:border-slate-700 mention--box"
  >
    <ul class="vertical dropdown menu">
      <woot-dropdown-item
        v-for="(item, index) in items"
        :id="`mention-item-${index}`"
        :key="item.key"
        class="!mb-0"
        @mouseover="onHover(index)"
      >
        <button
          class="flex group flex-col gap-0.5 overflow-hidden cursor-pointer items-start rounded-none py-2.5 px-2.5 justify-center w-full h-full text-left hover:bg-woot-50 dark:hover:bg-woot-800 border-x-0 border-t-0 border-b border-solid border-slate-100 dark:border-slate-700"
          :class="{
            ' bg-woot-25 dark:bg-woot-800': index === selectedIndex,
          }"
          @click="onListItemSelection(index)"
        >
          <p
            class="text-slate-900 dark:text-slate-100 group-hover:text-woot-500 dark:group-hover:text-woot-500 font-medium mb-0 text-sm overflow-hidden text-ellipsis whitespace-nowrap min-w-0 max-w-full"
            :class="{
              'text-woot-500 dark:text-woot-500': index === selectedIndex,
            }"
          >
            {{ item.description }}
          </p>
          <p
            class="text-slate-500 dark:text-slate-300 group-hover:text-woot-500 dark:group-hover:text-woot-500 mb-0 text-xs overflow-hidden text-ellipsis whitespace-nowrap min-w-0 max-w-full"
            :class="{
              'text-woot-500 dark:text-woot-500': index === selectedIndex,
            }"
          >
            {{ variableKey(item) }}
          </p>
        </button>
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
    type: {
      type: String,
      default: 'canned',
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
    adjustScroll() {},
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
    variableKey(item = {}) {
      return this.type === 'variable' ? `{{${item.label}}}` : `/${item.label}`;
    },
  },
};
</script>

<style scoped lang="scss">
.mention--box {
  .dropdown-menu__item:last-child > button {
    @apply border-0;
  }
}

.canned-item__button::v-deep .button__content {
  @apply overflow-hidden text-ellipsis whitespace-nowrap;
}
</style>
