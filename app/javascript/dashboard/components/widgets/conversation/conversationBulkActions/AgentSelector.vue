<template>
  <div class="bulk-action__agents">
    <div class="triangle">
      <svg height="12" viewBox="0 0 24 12" width="24">
        <path
          d="M20 12l-8-8-12 12"
          fill="var(--white)"
          fill-rule="evenodd"
          stroke="var(--s-50)"
          stroke-width="1px"
        />
      </svg>
    </div>
    <div class="header flex-between">
      <span>{{ $t('BULK_ACTION.AGENT_SELECT_LABEL') }}</span>
      <woot-button
        size="tiny"
        variant="clear"
        color-scheme="secondary"
        icon="dismiss"
        @click="onClose"
      />
    </div>
    <div class="container">
      <div
        v-if="assignableAgentsUiFlags.isFetching"
        class="agent__list-loading"
      >
        <spinner />
        <p>{{ $t('BULK_ACTION.AGENT_LIST_LOADING') }}</p>
      </div>
      <div v-else class="agent__list-container">
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
                conversationCount,
                conversationLabel,
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
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import Spinner from 'shared/components/Spinner';
import { mixin as clickaway } from 'vue-clickaway';

export default {
  components: {
    Thumbnail,
    Spinner,
  },
  mixins: [clickaway],
  props: {
    selectedInboxes: {
      type: Array,
      default: () => [],
    },
    conversationCount: {
      type: Number,
      default: 0,
    },
  },
  data() {
    return {
      query: '',
      selectedAgent: null,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'bulkActions/getUIFlags',
      inboxes: 'inboxes/getInboxes',
      assignableAgentsUiFlags: 'inboxAssignableAgents/getUIFlags',
    }),
    filteredAgents() {
      if (this.query) {
        return this.assignableAgents.filter(agent =>
          agent.name.toLowerCase().includes(this.query.toLowerCase())
        );
      }
      return this.assignableAgents;
    },
    assignableAgents() {
      return this.$store.getters['inboxAssignableAgents/getAssignableAgents'](
        this.selectedInboxes.join(',')
      );
    },
    conversationLabel() {
      return this.conversationCount > 1 ? 'conversations' : 'conversation';
    },
  },
  mounted() {
    this.$store.dispatch('inboxAssignableAgents/fetch', this.selectedInboxes);
  },
  methods: {
    submit() {
      this.$emit('select', this.selectedAgent);
    },
    goBack() {
      this.selectedAgent = null;
    },
    assignAgent(agent) {
      this.selectedAgent = agent;
    },
    onClose() {
      this.$emit('close');
    },
  },
};
</script>

<style scoped lang="scss">
.bulk-action__agents {
  background-color: var(--white);
  border-radius: var(--border-radius-large);
  border: 1px solid var(--s-50);
  box-shadow: var(--shadow-dropdown-pane);
  max-width: 75%;
  position: absolute;
  right: var(--space-small);
  top: var(--space-larger);
  transform-origin: top right;
  width: auto;
  z-index: var(--z-index-twenty);
  min-width: var(--space-giga);
  .header {
    padding: var(--space-one);

    span {
      font-size: var(--font-size-small);
      font-weight: var(--font-weight-medium);
    }
  }

  .container {
    max-height: var(--space-giga);
    overflow-y: auto;
    .agent__list-container {
      height: 100%;
    }
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
  .triangle {
    display: block;
    z-index: var(--z-index-one);
    position: absolute;
    top: calc(var(--space-slab) * -1);
    right: var(--space-micro);
    text-align: left;
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
.search-container {
  padding: 0 var(--space-one);
  position: sticky;
  top: 0;
  z-index: var(--z-index-twenty);
  background-color: var(--white);
}

.agent__list-loading {
  height: calc(95% - var(--space-one));
  margin: var(--space-one);
  border-radius: var(--border-radius-medium);
  background-color: var(--s-50);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-direction: column;
  padding: var(--space-two);
}
</style>
