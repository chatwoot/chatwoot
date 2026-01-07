<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { getUnixTime } from 'date-fns';
import { findSnoozeTime } from 'dashboard/helper/snoozeHelpers';
import { emitter } from 'shared/helpers/mitt';
import { useBulkActions } from 'dashboard/composables/chatlist/useBulkActions.js';
import wootConstants from 'dashboard/constants/globals';
import {
  CMD_BULK_ACTION_SNOOZE_CONVERSATION,
  CMD_BULK_ACTION_REOPEN_CONVERSATION,
  CMD_BULK_ACTION_RESOLVE_CONVERSATION,
} from 'dashboard/helper/commandbar/events';

import NextButton from 'dashboard/components-next/button/Button.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import BulkAgentActions from './BulkAgentActions.vue';
import BulkUpdateActions from './BulkUpdateActions.vue';
import BulkLabelActions from './BulkLabelActions.vue';
import BulkTeamActions from './BulkTeamActions.vue';
import CustomSnoozeModal from 'dashboard/components/CustomSnoozeModal.vue';

const props = defineProps({
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
});

const emit = defineEmits(['selectAllConversations']);

const {
  onAssignAgent,
  onAssignLabels,
  onAssignTeamsForBulk: onAssignTeam,
  onUpdateConversations,
} = useBulkActions();

const showCustomTimeSnoozeModal = ref(false);

function onCmdSnoozeConversation(snoozeType) {
  if (snoozeType === wootConstants.SNOOZE_OPTIONS.UNTIL_CUSTOM_TIME) {
    showCustomTimeSnoozeModal.value = true;
  } else {
    onUpdateConversations('snoozed', findSnoozeTime(snoozeType) || null);
  }
}

function onCmdReopenConversation() {
  onUpdateConversations('open', null);
}

function onCmdResolveConversation() {
  onUpdateConversations('resolved', null);
}

function customSnoozeTime(customSnoozedTime) {
  showCustomTimeSnoozeModal.value = false;
  if (customSnoozedTime) {
    onUpdateConversations('snoozed', getUnixTime(customSnoozedTime));
  }
}

function hideCustomSnoozeModal() {
  showCustomTimeSnoozeModal.value = false;
}

// Computed property with getter/setter to enable v-model usage
const allSelected = computed({
  get: () => props.allConversationsSelected,
  set: value => {
    emit('selectAllConversations', value);
  },
});

onMounted(() => {
  emitter.on(CMD_BULK_ACTION_SNOOZE_CONVERSATION, onCmdSnoozeConversation);
  emitter.on(CMD_BULK_ACTION_REOPEN_CONVERSATION, onCmdReopenConversation);
  emitter.on(CMD_BULK_ACTION_RESOLVE_CONVERSATION, onCmdResolveConversation);
});

onUnmounted(() => {
  emitter.off(CMD_BULK_ACTION_SNOOZE_CONVERSATION, onCmdSnoozeConversation);
  emitter.off(CMD_BULK_ACTION_REOPEN_CONVERSATION, onCmdReopenConversation);
  emitter.off(CMD_BULK_ACTION_RESOLVE_CONVERSATION, onCmdResolveConversation);
});
</script>

<template>
  <div
    class="pt-3 pb-2 px-2 relative z-10 after:absolute after:inset-x-0 after:-bottom-2.5 after:bg-gradient-to-b after:from-n-surface-1 after:from-40% after:to-transparent after:h-4 after:pointer-events-none after:z-10"
  >
    <div
      class="flex items-center justify-between p-2 bg-n-button-color outline outline-1 -outline-offset-1 rounded-[10px] outline-n-weak"
    >
      <div class="ltr:ml-0.5 rtl:mr-0.5 flex items-center gap-1">
        <label class="cursor-pointer flex items-center gap-1.5">
          <Checkbox
            v-model="allSelected"
            :indeterminate="!allConversationsSelected"
          />
          <span class="cursor-pointer">
            {{
              $t('BULK_ACTION.CONVERSATIONS_SELECTED', {
                conversationCount: conversations.length,
              })
            }}
          </span>
        </label>
        <div class="w-px h-3 bg-n-weak rounded-lg ltr:ml-1 rtl:mr-1" />
        <NextButton
          :label="$t('BULK_ACTION.CLEAR_SELECTION')"
          ghost
          class="!text-n-blue-11 !px-1 !h-6"
          sm
          @click="allSelected = false"
        />
      </div>
      <div class="flex items-center gap-2">
        <BulkLabelActions @assign="onAssignLabels" />
        <BulkUpdateActions
          :show-resolve="!showResolvedAction"
          :show-reopen="!showOpenAction"
          :show-snooze="!showSnoozedAction"
          @update="onUpdateConversations"
        />
        <BulkAgentActions
          :selected-inboxes="selectedInboxes"
          :conversation-count="conversations.length"
          @select="onAssignAgent"
        />
        <BulkTeamActions
          :conversation-count="conversations.length"
          @select="onAssignTeam"
        />
      </div>
    </div>
    <div
      v-if="allConversationsSelected"
      class="bg-n-amber-2 outline -outline-offset-1 outline-1 outline-n-amber-5 rounded-lg text-sm mt-2 py-1.5 px-2 text-n-amber-text"
    >
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
