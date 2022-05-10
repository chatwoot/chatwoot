<template>
  <div class="bulk-action__container flex-between">
    <div class="bulk-action__panel flex-between">
      <input
        ref="selectAllCheck"
        type="checkbox"
        class="checkbox"
        :checked="allConversationsSelected"
        @change="selectAll($event)"
      />
      <span>
        {{
          $t('BULK_ACTION.CONVERSATIONS_SELECTED', {
            conversationCount: conversations.length,
          })
        }}
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
    <transition name="menu-slide">
      <div v-if="showAgentsList" class="bulk-action__agents">
        <div class="header flex-between">
          <span>{{ $t('BULK_ACTION.AGENT_SELECT_LABEL') }}</span>
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
                  v-model="query"
                  type="search"
                  placeholder="Search"
                  class="agent--search_input"
                />
              </div>
            </li>
            <li v-for="agent in filteredAgents" :key="agent.id">
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
              {{
                $t('BULK_ACTION.ASSIGN_CONFIRMATION_LABEL', {
                  conversationCount: conversations.length,
                })
              }}
              <strong>
                {{ selectedAgent.name }}
              </strong>
            </p>
            <div class="agent-confirmation-actions">
              <woot-button
                color-scheme="primary"
                variant="smooth"
                @click="goBack"
              >
                {{ $t('BULK_ACTION.GO_BACK_LABEL') }}
              </woot-button>
              <woot-button
                color-scheme="primary"
                variant="flat"
                :is-loading="uiFlags.isUpdating"
                @click="submit"
              >
                {{ $t('BULK_ACTION.ASSIGN_LABEL') }}
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
    allConversationsSelected: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      showAgentsList: false,
      query: '',
      selectedAgent: null,
    };
  },
  computed: {
    ...mapGetters({
      agents: 'agents/getAgents',
      uiFlags: 'bulkActions/getUIFlags',
    }),
    filteredAgents() {
      return this.agents.filter(agent =>
        agent.name.toLowerCase().includes(this.query.toLowerCase())
      );
    },
  },
  mounted() {
    this.$refs.selectAllCheck.indeterminate = true;
  },
  methods: {
    assignAgent(agent) {
      this.selectedAgent = agent;
    },
    selectAll(e) {
      this.$emit('selectAllConversations', e.target.checked);
    },
    goBack() {
      this.selectedAgent = null;
    },
    submit() {
      this.$emit('assignAgent', this.selectedAgent);
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
  z-index: var(--z-index-twenty);
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
  right: var(--space-small);
  width: 100%;
  box-shadow: 0 0.8rem 1.6rem rgb(50 50 93 / 8%),
    0 0.4rem 1.2rem rgb(0 0 0 / 7%);
  border-radius: 0.8rem;
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
      padding: 0 var(--space-one);
      border: 1px solid var(--s-100);
      border-radius: var(--border-radius-medium);
      background-color: var(--s-50);
      .search-icon {
        color: var(--s-400);
      }

      .agent--search_input {
        border: 0;
        font-size: var(--font-size-mini);
        margin: 0;
        background-color: transparent;
        height: unset;
      }
    }
  }
}
ul {
  margin: 0;
  list-style: none;
}

.agent-list-item {
  display: flex;
  align-items: center;
  padding: var(--space-one);
  cursor: pointer;
  &:hover {
    background-color: var(--s-50);
  }
  span {
    font-size: var(--font-size-small);
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
