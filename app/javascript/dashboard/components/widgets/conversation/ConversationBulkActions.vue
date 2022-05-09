<template>
  <div class="bulk-action__container flex-between">
    <div class="bulk-action__panel flex-between">
      <input
        ref="selectAllCheck"
        type="checkbox"
        class="checkbox"
        @change="selectAll($event)"
      />
      <span>
        {{ conversations.length }}
        {{ conversations.length > 1 ? 'conversations' : 'conversation' }}
        selected
      </span>
    </div>
    <div class="bulk-action__actions flex-between">
      <woot-button
        v-tooltip="'Resolve'"
        size="tiny"
        variant="smooth"
        color-scheme="success"
        icon="checkmark"
        class="mr-small"
      />
      <woot-button
        v-tooltip="'Assign Agent'"
        size="tiny"
        variant="flat"
        color-scheme="secondary"
        icon="person-assign"
        @click="showAgentsList = true"
      />
    </div>
    <transition name="fade">
      <div v-if="showAgentsList" class="bulk-action__agents">
        <div class="header flex-between">
          <span>Select Agent</span>
          <woot-button
            size="tiny"
            variant="clear"
            color-scheme="secondary"
            icon="dismiss"
            @click="showAgentsList = false"
          />
        </div>
        <div class="container">
          <ul v-if="!selectedAgent">
            <li class="search-container">
              <div class="agent-list-search flex-between">
                <fluent-icon icon="search" class="search-icon" size="16" />
                <input
                  ref="search"
                  type="search"
                  placeholder="Search"
                  class="agent--search_input"
                  @input="search"
                />
              </div>
              <span>{{ query }}</span>
            </li>
            <li v-for="agent in agents" :key="agent.id">
              <div class="agent-list-item" @click="assignAgent(agent)">
                <thumbnail
                  src="agent.thumbnail"
                  :username="agent.name"
                  size="22px"
                  class="margin-right-small"
                />
                <span class="reports-option__title">{{ agent.name }}</span>
              </div>
            </li>
          </ul>
          <div v-else class="agent-confirmation-container">
            <p>
              Are you sure you want to assign
              {{ conversations.length }} conversations to
              <strong>
                {{ selectedAgent.name }}
              </strong>
            </p>
            <div class="agent-confirmation-actions">
              <woot-button color-scheme="primary" variant="smooth">
                Go Back
              </woot-button>
              <woot-button color-scheme="primary" variant="flat">
                Assign
              </woot-button>
            </div>
          </div>
        </div>
      </div>
    </transition>
  </div>
</template>

<script>
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import { mapGetters } from 'vuex';

export default {
  components: {
    Thumbnail,
  },
  props: {
    conversations: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      showAgentsList: false,
      query: null,
      debounce: null,
      selectedAgent: null,
    };
  },
  computed: {
    ...mapGetters({
      agents: 'agents/getAgents',
    }),
  },
  mounted() {
    this.$refs.selectAllCheck.indeterminate = true;
  },
  methods: {
    search(e) {
      clearTimeout(this.debounce);
      this.debounce = setTimeout(() => {
        this.query = e.target.value;
      }, 600);
    },
    assignAgent(agent) {
      this.selectedAgent = agent;
    },
    selectAll(e) {
      this.$emit('selectAllConversations', e.target.checked);
    },
  },
};
</script>

<style scoped lang="scss">
.flex-between {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.bulk-action__container {
  padding: var(--space-one);
  background-color: var(--s-25);
  border-top: 1px solid var(--s-100);
  position: relative;
}
.search-container {
  padding: 0 var(--space-one);
  position: sticky;
  top: 0;
  z-index: 20;
  background-color: var(--white);
}

.bulk-action__panel {
  span {
    font-size: var(--font-size-mini);
    margin-left: var(--space-smaller);
  }
  input[type='checkbox'] {
    margin: var(--space-zero);
  }
}

.mr-small {
  margin-right: var(--space-smaller);
}

.bulk-action__agents {
  position: absolute;
  bottom: 40px;
  right: 8px;
  width: 100%;
  box-shadow: 0 0.8rem 1.6rem rgb(50 50 93 / 8%),
    0 0.4rem 1.2rem rgb(0 0 0 / 7%);
  border-radius: 0.8rem;
  border: 1px solid #f1f5f8;
  border: 1px solid var(--s-50);
  background-color: var(--white);
  width: 75%;
  .header {
    padding: var(--space-one);
    span {
      font-size: var(--font-size-default);
      font-weight: var(--font-weight-medium);
    }
  }
  .container {
    height: 240px;
    overflow-y: auto;

    .agent-list-search {
      padding: 0 1rem;
      border: 1px solid var(--s-100);
      border-radius: 0.75rem;
      background-color: var(--s-50);
      .search-icon {
        color: var(--s-400);
      }

      .agent--search_input {
        border: 0;
        font-size: 12px;
        margin: 0;
        background-color: transparent;
        height: unset;
      }
    }
  }
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s;
}
.fade-enter,
.fade-leave-active {
  opacity: 0;
}
ul {
  margin: 0;
  list-style: none;
}

.agent-list-item {
  display: flex;
  align-items: center;
  padding: 1rem;
  cursor: pointer;
  &:hover {
    background-color: var(--s-50);
  }
  span {
    font-size: 14px;
  }
}

.agent-confirmation-container {
  display: flex;
  flex-direction: column;
  height: 100%;
  padding: var(--space-one);
  p {
    flex-grow: 1;
  }
  .agent-confirmation-actions {
    width: 100%;
    display: grid;
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 1rem;
  }
}
</style>
