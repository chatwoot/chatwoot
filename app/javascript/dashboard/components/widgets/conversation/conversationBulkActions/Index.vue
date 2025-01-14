<script>
import { getUnixTime } from 'date-fns';
import { findSnoozeTime } from 'dashboard/helper/snoozeHelpers';
import { emitter } from 'shared/helpers/mitt';
import wootConstants from 'dashboard/constants/globals';
import {
  CMD_BULK_ACTION_SNOOZE_CONVERSATION,
  CMD_BULK_ACTION_REOPEN_CONVERSATION,
  CMD_BULK_ACTION_RESOLVE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';

import AgentSelector from './AgentSelector.vue';
import UpdateActions from './UpdateActions.vue';
import LabelActions from './LabelActions.vue';
import TeamActions from './TeamActions.vue';
import CustomSnoozeModal from 'dashboard/components/CustomSnoozeModal.vue';
export default {
  components: {
    AgentSelector,
    UpdateActions,
    LabelActions,
    TeamActions,
    CustomSnoozeModal,
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
  emits: [
    'selectAllConversations',
    'assignAgent',
    'updateConversations',
    'assignLabels',
    'assignTeam',
    'resolveConversations',
  ],
  data() {
    return {
      showAgentsList: false,
      showUpdateActions: false,
      showLabelActions: false,
      showTeamsList: false,
      popoverPositions: {},
      showCustomTimeSnoozeModal: false,
    };
  },
  mounted() {
    emitter.on(
      CMD_BULK_ACTION_SNOOZE_CONVERSATION,
      this.onCmdSnoozeConversation
    );
    emitter.on(
      CMD_BULK_ACTION_REOPEN_CONVERSATION,
      this.onCmdReopenConversation
    );
    emitter.on(
      CMD_BULK_ACTION_RESOLVE_CONVERSATION,
      this.onCmdResolveConversation
    );
  },
  unmounted() {
    emitter.off(
      CMD_BULK_ACTION_SNOOZE_CONVERSATION,
      this.onCmdSnoozeConversation
    );
    emitter.off(
      CMD_BULK_ACTION_REOPEN_CONVERSATION,
      this.onCmdReopenConversation
    );
    emitter.off(
      CMD_BULK_ACTION_RESOLVE_CONVERSATION,
      this.onCmdResolveConversation
    );
  },
  methods: {
    onCmdSnoozeConversation(snoozeType) {
      if (snoozeType === wootConstants.SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME) {
        this.showCustomTimeSnoozeModal = true;
      } else {
        this.updateConversations('snoozed', findSnoozeTime(snoozeType) || null);
      }
    },
    onCmdReopenConversation() {
      this.updateConversations('open', null);
    },
    onCmdResolveConversation() {
      this.updateConversations('resolved', null);
    },
    customSnoozeTime(customSnoozedTime) {
      this.showCustomTimeSnoozeModal = false;
      if (customSnoozedTime) {
        this.updateConversations('snoozed', getUnixTime(customSnoozedTime));
      }
    },
    hideCustomSnoozeModal() {
      this.showCustomTimeSnoozeModal = false;
    },
    selectAll(e) {
      this.$emit('selectAllConversations', e.target.checked);
    },
    submit(agent) {
      this.$emit('assignAgent', agent);
    },
    updateConversations(status, snoozedUntil) {
      this.$emit('updateConversations', status, snoozedUntil);
    },
    assignLabels(labels) {
      this.$emit('assignLabels', labels);
    },
    assignTeam(team) {
      this.$emit('assignTeam', team);
    },
    resolveConversations() {
      this.$emit('resolveConversations');
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
    toggleTeamsList() {
      this.showTeamsList = !this.showTeamsList;
    },
  },
};
</script>

<template>
  <div class="bulk-action__container">
    <div class="flex items-center justify-between">
      <label class="flex items-center justify-between bulk-action__panel">
        <input
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
      <div class="flex items-center gap-1 bulk-action__actions">
        <woot-button
          v-tooltip="$t('BULK_ACTION.LABELS.ASSIGN_LABELS')"
          size="tiny"
          variant="smooth"
          color-scheme="secondary"
          icon="tag"
          @click="toggleLabelActions"
        />
        <woot-button
          v-tooltip="$t('BULK_ACTION.UPDATE.CHANGE_STATUS')"
          size="tiny"
          variant="smooth"
          color-scheme="secondary"
          icon="repeat"
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
        <woot-button
          v-tooltip="$t('BULK_ACTION.ASSIGN_TEAM_TOOLTIP')"
          size="tiny"
          variant="smooth"
          color-scheme="secondary"
          icon="people-team-add"
          @click="toggleTeamsList"
        />
      </div>
      <transition name="popover-animation">
        <LabelActions
          v-if="showLabelActions"
          class="label-actions-box"
          @assign="assignLabels"
          @close="showLabelActions = false"
        />
      </transition>
      <transition name="popover-animation">
        <UpdateActions
          v-if="showUpdateActions"
          class="update-actions-box"
          :selected-inboxes="selectedInboxes"
          :conversation-count="conversations.length"
          :show-resolve="!showResolvedAction"
          :show-reopen="!showOpenAction"
          :show-snooze="!showSnoozedAction"
          @update="updateConversations"
          @close="showUpdateActions = false"
        />
      </transition>
      <transition name="popover-animation">
        <AgentSelector
          v-if="showAgentsList"
          class="agent-actions-box"
          :selected-inboxes="selectedInboxes"
          :conversation-count="conversations.length"
          @select="submit"
          @close="showAgentsList = false"
        />
      </transition>
      <transition name="popover-animation">
        <TeamActions
          v-if="showTeamsList"
          class="team-actions-box"
          @assign-team="assignTeam"
          @close="showTeamsList = false"
        />
      </transition>
    </div>
    <div v-if="allConversationsSelected" class="bulk-action__alert">
      {{ $t('BULK_ACTION.ALL_CONVERSATIONS_SELECTED_ALERT') }}
    </div>
    <woot-modal
      v-model:show="showCustomTimeSnoozeModal"
      :on-close="hideCustomSnoozeModal"
    >
      <CustomSnoozeModal
        @close="hideCustomSnoozeModal"
        @choose-time="customSnoozeTime"
      />
    </woot-modal>
  </div>
</template>

<style scoped lang="scss">
// For RTL direction view
.app-rtl--wrapper {
  .bulk-action__actions {
    ::v-deep .button--only-icon:last-child {
      margin-right: var(--space-smaller);
    }
  }
}

.bulk-action__container {
  @apply p-4 relative border-b border-solid border-slate-100 dark:border-slate-600/70;
}

.bulk-action__panel {
  @apply cursor-pointer;

  span {
    @apply text-xs my-0 mx-1;
  }

  input[type='checkbox'] {
    @apply cursor-pointer m-0;
  }
}

.bulk-action__alert {
  @apply bg-yellow-50 text-yellow-700 rounded text-xs mt-2 py-1 px-2 border border-solid border-yellow-300 dark:border-yellow-300/10 dark:bg-yellow-200/20 dark:text-yellow-400;
}

.popover-animation-enter-active,
.popover-animation-leave-active {
  transition: transform ease-out 0.1s;
}

.popover-animation-enter {
  transform: scale(0.95);
  @apply opacity-0;
}

.popover-animation-enter-to {
  transform: scale(1);
  @apply opacity-100;
}

.popover-animation-leave {
  transform: scale(1);
  @apply opacity-100;
}

.popover-animation-leave-to {
  transform: scale(0.95);
  @apply opacity-0;
}

.label-actions-box {
  --triangle-position: 5.3125rem;
}
.update-actions-box {
  --triangle-position: 3.5rem;
}
.agent-actions-box {
  --triangle-position: 1.75rem;
}
.team-actions-box {
  --triangle-position: 0.125rem;
}
</style>
