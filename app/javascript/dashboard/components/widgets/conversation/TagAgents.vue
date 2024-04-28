<template>
  <ul
    v-if="items.length"
    class="vertical dropdown menu mention--box"
    :class="{ 'with-bottom-border': items.length <= 4 }"
  >
    <li
      v-for="(agent, index) in items"
      :id="`mention-item-${index}`"
      :key="agent.id"
      :class="{ active: index === selectedIndex }"
      class="last:mb-2 items-center rounded-md flex p-2"
      @click="onAgentSelect(index)"
      @mouseover="onHover(index)"
    >
      <div class="mr-2">
        <woot-thumbnail
          :src="agent.thumbnail"
          :username="agent.name"
          size="32px"
        />
      </div>
      <div
        class="flex-1 max-w-full overflow-hidden whitespace-nowrap text-ellipsis"
      >
        <h5
          class="mention--user-name mb-0 text-sm text-slate-900 dark:text-slate-100 overflow-hidden whitespace-nowrap text-ellipsis"
        >
          {{ agent.name }}
        </h5>
        <div
          class="mention--email overflow-hidden whitespace-nowrap text-ellipsis text-slate-700 dark:text-slate-300 text-xs"
        >
          {{ agent.email }}
        </div>
      </div>
    </li>
  </ul>
</template>

<script>
import { mapGetters } from 'vuex';
import mentionSelectionKeyboardMixin from '../mentions/mentionSelectionKeyboardMixin';
export default {
  mixins: [mentionSelectionKeyboardMixin],
  props: {
    searchKey: {
      type: String,
      default: '',
    },
  },
  data() {
    return { selectedIndex: 0 };
  },
  computed: {
    ...mapGetters({ agents: 'agents/getVerifiedAgents' }),
    items() {
      if (!this.searchKey) {
        return this.agents;
      }

      return this.agents.filter(agent =>
        agent.name
          .toLocaleLowerCase()
          .includes(this.searchKey.toLocaleLowerCase())
      );
    },
  },
  watch: {
    items(newListOfAgents) {
      if (newListOfAgents.length < this.selectedIndex + 1) {
        this.selectedIndex = 0;
      }
    },
  },

  methods: {
    adjustScroll() {
      this.$nextTick(() => {
        this.$el.scrollTop = 50 * this.selectedIndex;
      });
    },
    onHover(index) {
      this.selectedIndex = index;
    },
    onAgentSelect(index) {
      this.selectedIndex = index;
      this.onSelect();
    },
    onSelect() {
      this.$emit('click', this.items[this.selectedIndex]);
    },
  },
};
</script>

<style scoped lang="scss">
.mention--box {
  @apply bg-white text-sm dark:bg-slate-700 rounded-md overflow-auto absolute w-full z-20 pt-2 px-2 pb-0 shadow-md left-0 leading-[1.2] bottom-full max-h-[12.5rem] border-t border-solid border-slate-75 dark:border-slate-800;

  &.with-bottom-border {
    @apply border-b-[0.5rem] border-solid border-white dark:border-slate-600;

    li {
      &:last-child {
        @apply mb-0;
      }
    }
  }

  li {
    &.active {
      @apply bg-slate-50 dark:bg-slate-800;

      .mention--user-name {
        @apply text-slate-900 dark:text-slate-100;
      }
      .mention--email {
        @apply text-slate-800 dark:text-slate-200;
      }
    }
  }
}
</style>
