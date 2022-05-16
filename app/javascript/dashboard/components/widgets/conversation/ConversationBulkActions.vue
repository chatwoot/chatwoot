<template>
  <div class="bulk-action__container">
    <div class="flex-between">
      <label class="bulk-action__panel flex-between">
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
      </label>
      <div class="bulk-action__actions flex-between">
        <woot-button
          v-tooltip="$t('BULK_ACTION.RESOLVE_TOOLTIP')"
          size="tiny"
          variant="flat"
          color-scheme="success"
          icon="checkmark"
          class="margin-right-smaller"
          @click="resolveConversations"
        />
        <woot-button
          v-tooltip="$t('BULK_ACTION.ASSIGN_AGENT_TOOLTIP')"
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
    <div v-if="allConversationsSelected" class="bulk-action__alert">
      {{ $t('BULK_ACTION.ALL_CONVERSATIONS_SELECTED_ALERT') }}
    </div>
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
      uiFlags: 'bulkActions/getUIFlags',
      inboxes: 'inboxes/getInboxes',
    }),
    filteredAgents() {
      return this.assignableAgents.filter(agent =>
        agent.name.toLowerCase().includes(this.query.toLowerCase())
      );
    },
    assignableAgents() {
      return this.$store.getters['inboxAssignableAgents/getAssignableAgents'](
        this.inboxes[0].id
      );
    },
  },
  mounted() {
    this.$refs.selectAllCheck.indeterminate = true;
    this.$store.dispatch('inboxAssignableAgents/fetch', {
      inboxId: this.inboxes[0].id,
    });
  },
  methods: {
    assignAgent(agent) {
      this.selectedAgent = agent;
    },
    selectAll(e) {
      this.$emit('select-all-conversations', e.target.checked);
    },
    goBack() {
      this.selectedAgent = null;
    },
    submit() {
      this.$emit('assign-agent', this.selectedAgent);
    },
    resolveConversations() {
      this.$emit('resolve-conversations');
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
  padding: var(--space-normal) var(--space-one);
  border-top: 1px solid var(--s-100);
  background-color: var(--s-50);
  position: relative;
  box-shadow: var(--shadow-bulk-action-container);
}
.search-container {
  padding: 0 var(--space-one);
  position: sticky;
  top: 0;
  z-index: var(--z-index-twenty);
  background-color: var(--white);
}

.bulk-action__panel {
  cursor: pointer;
  span {
    font-size: var(--font-size-mini);
    margin-left: var(--space-smaller);
  }
  input[type='checkbox'] {
    margin: var(--space-zero);
    cursor: pointer;
  }
}

.bulk-action__agents {
  position: absolute;
  bottom: 40px;
  right: var(--space-small);
  width: 100%;
  box-shadow: var(--shadow-dropdown-pane);
  border-radius: var(--border-radius-large);
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
    gap: var(--space-one);
  }
}
.bulk-action__alert {
  border: 1px solid var(--y-300);
  background-color: var(--y-50);
  color: var(--y-700);
  padding: var(--space-half) var(--space-one);
  font-size: var(--font-size-mini);
  border-radius: var(--border-radius-small);
  margin-top: var(--space-small);
}
</style>
