<template>
  <ul
    v-if="items.length"
    class="vertical dropdown menu mention--box"
    :style="{ top: getTopSpacing() + 'rem' }"
    :class="{ 'with-bottom-border': items.length <= 4 }"
  >
    <li
      v-for="(agent, index) in items"
      :id="`mention-item-${index}`"
      :key="agent.id"
      :class="{ active: index === selectedIndex }"
      @click="onAgentSelect(index)"
      @mouseover="onHover(index)"
    >
      <div class="mention--thumbnail">
        <woot-thumbnail
          :src="agent.thumbnail"
          :username="agent.name"
          size="32px"
        />
      </div>
      <div class="mention--metadata text-truncate">
        <h5 class="text-block-title mention--user-name text-truncate">
          {{ agent.name }}
        </h5>
        <div class="text-truncate mention--email text-truncate">
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
    getTopSpacing() {
      if (this.items.length <= 4) {
        return -(this.items.length * 5 + 1.7);
      }
      return -20;
    },
    handleKeyboardEvent(e) {
      this.processKeyDownEvent(e);
      this.$el.scrollTop = 50 * this.selectedIndex;
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
  background: var(--white);
  border-top: 1px solid var(--color-border);
  font-size: var(--font-size-small);
  left: 0;
  line-height: 1.2;
  max-height: 20rem;
  overflow: auto;
  padding: var(--space-small) var(--space-small) 0 var(--space-small);
  position: absolute;
  width: 100%;
  z-index: 100;

  &.with-bottom-border {
    border-bottom: var(--space-small) solid var(--white);

    li {
      &:last-child {
        margin-bottom: 0;
      }
    }
  }

  li {
    align-items: center;
    border-radius: var(--border-radius-normal);
    display: flex;
    padding: var(--space-small);

    &.active {
      background: var(--s-50);

      .mention--user-name {
        color: var(--s-900);
      }
      .mention--email {
        color: var(--s-800);
      }
    }

    &:last-child {
      margin-bottom: var(--space-small);
    }
  }
}

.mention--thumbnail {
  margin-right: var(--space-small);
}

.mention--user-name {
  margin-bottom: 0;
}

.mention--email {
  color: var(--s-700);
  font-size: var(--font-size-mini);
}

.mention--metadata {
  flex: 1;
  max-width: 100%;
}
</style>
