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
        <agent-selector
          v-if="showAgentsList"
          :selected-inboxes="selectedInboxes"
          :conversation-count="conversations.length"
          @select="submit"
          @close="showAgentsList = false"
        />
      </transition>
    </div>
    <div v-if="allConversationsSelected" class="bulk-action__alert">
      {{ $t('BULK_ACTION.ALL_CONVERSATIONS_SELECTED_ALERT') }}
    </div>
  </div>
</template>

<script>
import AgentSelector from './AgentSelector.vue';
export default {
  components: {
    AgentSelector,
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
    selectedInboxes: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      showAgentsList: false,
    };
  },
  mounted() {
    this.$refs.selectAllCheck.indeterminate = true;
  },
  methods: {
    selectAll(e) {
      this.$emit('select-all-conversations', e.target.checked);
    },
    submit(agent) {
      this.$emit('assign-agent', agent);
    },
    resolveConversations() {
      this.$emit('resolve-conversations');
    },
  },
};
</script>

<style scoped lang="scss">
.flex-between {
  align-items: center;
  display: flex;
  justify-content: space-between;
}

.bulk-action__container {
  background-color: var(--s-50);
  border-top: 1px solid var(--s-100);
  box-shadow: var(--shadow-bulk-action-container);
  padding: var(--space-normal) var(--space-one);
  position: relative;
}

.bulk-action__panel {
  cursor: pointer;

  span {
    font-size: var(--font-size-mini);
    margin-left: var(--space-smaller);
  }

  input[type='checkbox'] {
    cursor: pointer;
    margin: var(--space-zero);
  }
}

.bulk-action__alert {
  background-color: var(--y-50);
  border-radius: var(--border-radius-small);
  border: 1px solid var(--y-300);
  color: var(--y-700);
  font-size: var(--font-size-mini);
  margin-top: var(--space-small);
  padding: var(--space-half) var(--space-one);
}
</style>
