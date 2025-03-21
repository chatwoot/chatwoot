<script>
import { mapGetters } from 'vuex';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import Spinner from 'shared/components/Spinner.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    Thumbnail,
    Spinner,
    NextButton,
  },
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
  emits: ['select', 'close'],
  data() {
    return {
      query: '',
      selectedAgent: null,
      goBackToAgentList: false,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'bulkActions/getUIFlags',
      assignableAgentsUiFlags: 'inboxAssignableAgents/getUIFlags',
    }),
    filteredAgents() {
      if (this.query) {
        return this.assignableAgents.filter(agent =>
          agent.name.toLowerCase().includes(this.query.toLowerCase())
        );
      }
      return [
        {
          confirmed: true,
          name: 'None',
          id: null,
          role: 'agent',
          account_id: 0,
          email: 'None',
        },
        ...this.assignableAgents,
      ];
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
      this.goBackToAgentList = true;
      this.selectedAgent = null;
    },
    assignAgent(agent) {
      this.selectedAgent = agent;
    },
    onClose() {
      this.$emit('close');
    },
    onCloseAgentList() {
      if (this.selectedAgent === null && !this.goBackToAgentList) {
        this.onClose();
      }
      this.goBackToAgentList = false;
    },
  },
};
</script>

<template>
  <div v-on-clickaway="onCloseAgentList" class="bulk-action__agents">
    <div class="triangle">
      <svg height="12" viewBox="0 0 24 12" width="24">
        <path d="M20 12l-8-8-12 12" fill-rule="evenodd" stroke-width="1px" />
      </svg>
    </div>
    <div class="flex items-center justify-between header">
      <span>{{ $t('BULK_ACTION.AGENT_SELECT_LABEL') }}</span>
      <NextButton ghost xs slate icon="i-lucide-x" @click="onClose" />
    </div>
    <div class="container">
      <div
        v-if="assignableAgentsUiFlags.isFetching"
        class="agent__list-loading"
      >
        <Spinner />
        <p>{{ $t('BULK_ACTION.AGENT_LIST_LOADING') }}</p>
      </div>
      <div v-else class="agent__list-container">
        <ul v-if="!selectedAgent">
          <li class="search-container">
            <div
              class="flex items-center justify-between h-8 gap-2 agent-list-search"
            >
              <fluent-icon icon="search" class="search-icon" size="16" />
              <input
                v-model="query"
                type="search"
                :placeholder="$t('BULK_ACTION.SEARCH_INPUT_PLACEHOLDER')"
                class="reset-base !outline-0 !text-sm agent--search_input"
              />
            </div>
          </li>
          <li v-for="agent in filteredAgents" :key="agent.id">
            <div class="agent-list-item" @click="assignAgent(agent)">
              <Thumbnail
                :src="agent.thumbnail"
                :status="agent.availability_status"
                :username="agent.name"
                size="22px"
              />
              <span class="my-0 text-slate-800 dark:text-slate-75">
                {{ agent.name }}
              </span>
            </div>
          </li>
        </ul>
        <div v-else class="agent-confirmation-container">
          <p v-if="selectedAgent.id">
            {{
              $t('BULK_ACTION.ASSIGN_CONFIRMATION_LABEL', {
                conversationCount,
                conversationLabel,
              })
            }}
            <strong>
              {{ selectedAgent.name }}
            </strong>
            <span>?</span>
          </p>
          <p v-else>
            {{
              $t('BULK_ACTION.UNASSIGN_CONFIRMATION_LABEL', {
                conversationCount,
                conversationLabel,
              })
            }}
          </p>
          <div class="agent-confirmation-actions">
            <NextButton
              faded
              sm
              slate
              type="reset"
              :label="$t('BULK_ACTION.GO_BACK_LABEL')"
              @click="goBack"
            />
            <NextButton
              sm
              type="submit"
              :label="$t('BULK_ACTION.YES')"
              :is-loading="uiFlags.isUpdating"
              @click="submit"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.bulk-action__agents {
  @apply max-w-[75%] absolute right-2 top-12 origin-top-right w-auto z-20 min-w-[15rem] bg-n-alpha-3 backdrop-blur-[100px] border-n-weak rounded-lg border border-solid shadow-md;
  .header {
    @apply p-2.5;

    span {
      @apply text-sm font-medium;
    }
  }

  .container {
    @apply overflow-y-auto max-h-[15rem];
    .agent__list-container {
      @apply h-full;
    }
    .agent-list-search {
      @apply py-0 px-2.5 bg-n-alpha-black2 border border-solid border-n-strong rounded-md;
      .search-icon {
        @apply text-slate-400 dark:text-slate-200;
      }

      .agent--search_input {
        @apply border-0 text-xs m-0 dark:bg-transparent bg-transparent h-[unset] w-full;
      }
    }
  }
  .triangle {
    right: var(--triangle-position);
    @apply block z-10 absolute -top-3 text-left;

    svg path {
      @apply fill-n-alpha-3 backdrop-blur-[100px]  stroke-n-weak;
    }
  }
}
ul {
  @apply m-0 list-none;

  li {
    &:last-child {
      .agent-list-item {
        @apply last:rounded-b-lg;
      }
    }
  }
}

.agent-list-item {
  @apply flex items-center p-2.5 gap-2 cursor-pointer hover:bg-n-slate-3 dark:hover:bg-n-solid-3;
  span {
    @apply text-sm;
  }
}

.agent-confirmation-container {
  @apply flex flex-col h-full p-2.5;
  p {
    @apply flex-grow;
  }
  .agent-confirmation-actions {
    @apply w-full grid grid-cols-2 gap-2.5;
  }
}
.search-container {
  @apply py-0 px-2.5 sticky top-0 z-20 bg-n-alpha-3 backdrop-blur-[100px];
}

.agent__list-loading {
  @apply m-2.5 rounded-md bg-slate-25 dark:bg-slate-900 flex items-center justify-center flex-col p-5 h-[calc(95%-6.25rem)];
}
</style>
