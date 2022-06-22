<template>
  <div class="bulk-action__container">
    <div class="flex-between">
      <label class="bulk-action__panel flex-between">
        <input
          ref="selectAllCheck"
          type="checkbox"
          class="checkbox"
          :checked="allConversationsSelected"
          :indeterminate.prop="!allConversationsSelected"
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
          v-tooltip="$t('BULK_ACTION.LABELS.ASSIGN_LABELS')"
          size="tiny"
          variant="smooth"
          color-scheme="secondary"
          icon="tag"
          class="margin-right-smaller"
          @click="toggleLabelActions"
        />
        <woot-button
          v-tooltip="$t('BULK_ACTION.UPDATE.CHANGE_STATUS')"
          size="tiny"
          variant="smooth"
          color-scheme="secondary"
          icon="repeat"
          class="margin-right-smaller"
          @click="toggleUpdateActions"
        />
        <woot-button
          v-tooltip="$t('BULK_ACTION.ASSIGN_AGENT_TOOLTIP')"
          size="tiny"
          variant="smooth"
          color-scheme="secondary"
          icon="person-assign"
          @click="toggleAgentList"
        />
      </div>
      <transition name="popover-animation">
        <label-actions
          v-if="showLabelActions"
          @assign="assignLabels"
          @close="showLabelActions = false"
        />
      </transition>
      <transition name="popover-animation">
        <agent-selector
          v-if="showAgentsList"
          :selected-inboxes="selectedInboxes"
          :conversation-count="conversations.length"
          @select="submit"
          @close="showAgentsList = false"
        />
      </transition>
      <transition name="popover-animation">
        <update-actions
          v-if="showUpdateActions"
          :selected-inboxes="selectedInboxes"
          :conversation-count="conversations.length"
          :show-resolve="!showResolvedAction"
          :show-reopen="!showOpenAction"
          :show-snooze="!showSnoozedAction"
          @update="updateConversations"
          @close="showUpdateActions = false"
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
import UpdateActions from './UpdateActions.vue';
import LabelActions from './LabelActions.vue';
export default {
  components: {
    AgentSelector,
    UpdateActions,
    LabelActions,
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
    showOpenAction: {
      type: Boolean,
      default: false,
    },
    showResolvedAction: {
      type: Boolean,
      default: false,
    },
    showSnoozedAction: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      showAgentsList: false,
      showUpdateActions: false,
      showLabelActions: false,
    };
  },
  methods: {
    selectAll(e) {
      this.$emit('select-all-conversations', e.target.checked);
    },
    submit(agent) {
      this.$emit('assign-agent', agent);
    },
    updateConversations(status) {
      this.$emit('update-conversations', status);
    },
    assignLabels(labels) {
      this.$emit('assign-labels', labels);
    },
    resolveConversations() {
      this.$emit('resolve-conversations');
    },
    toggleUpdateActions() {
      this.showUpdateActions = !this.showUpdateActions;
    },
    toggleLabelActions() {
      this.showLabelActions = !this.showLabelActions;
    },
    toggleAgentList() {
      this.showAgentsList = !this.showAgentsList;
    },
  },
};
</script>

<style scoped lang="scss">
.bulk-action__container {
  border-bottom: 1px solid var(--s-100);
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

.popover-animation-enter-active,
.popover-animation-leave-active {
  transition: transform ease-out 0.1s;
}

.popover-animation-enter {
  opacity: 0;
  transform: scale(0.95);
}

.popover-animation-enter-to {
  opacity: 1;
  transform: scale(1);
}

.popover-animation-leave {
  opacity: 1;
  transform: scale(1);
}

.popover-animation-leave-to {
  opacity: 0;
  transform: scale(0.95);
}
</style>
