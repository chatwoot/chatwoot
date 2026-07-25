<script setup>
import { computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { useConversationAssignee } from 'dashboard/composables/useConversationAssignee';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  compact: {
    type: Boolean,
    default: false,
  },
  showSelfAssignButton: {
    type: Boolean,
    default: false,
  },
  borderless: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();
const store = useStore();

const {
  agentsList,
  assignedAgent,
  showSelfAssign,
  isAssigning,
  onClickAssignAgent,
  onSelfAssign,
} = useConversationAssignee();

const fetchAssignableAgents = () => {
  const inboxId = store.getters.getSelectedChat?.inbox_id;
  if (inboxId) {
    store.dispatch('inboxAssignableAgents/fetch', [inboxId]);
  }
};

onMounted(fetchAssignableAgents);

watch(
  () => store.getters.getSelectedChat?.inbox_id,
  () => fetchAssignableAgents()
);

const leftLabel = computed(() => {
  if (props.showSelfAssignButton && showSelfAssign.value) {
    return t('CONVERSATION_SIDEBAR.SELF_ASSIGN');
  }
  return (
    assignedAgent.value?.name || t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')
  );
});

const canSelfAssign = computed(
  () => props.showSelfAssignButton && showSelfAssign.value
);
</script>

<template>
  <!-- Header: split control (label | chevron) — no overflow-hidden so menu is visible -->
  <div
    v-if="compact"
    v-tooltip="t('CONVERSATION.HEADER.ASSIGNEE')"
    class="relative flex items-center h-8 min-w-[11rem] max-w-[14rem] rounded-lg outline outline-1 outline-n-weak bg-n-background shrink-0"
  >
    <button
      v-if="canSelfAssign"
      type="button"
      class="flex-1 min-w-0 h-full px-2.5 text-left text-sm font-medium text-n-blue-11 truncate rounded-none border-0 bg-transparent hover:bg-n-alpha-2 disabled:opacity-50"
      :disabled="isAssigning"
      @click="onSelfAssign"
    >
      {{ leftLabel }}
    </button>
    <span
      v-else
      class="flex-1 min-w-0 h-full px-2.5 flex items-center text-sm text-n-slate-12 truncate"
      :title="leftLabel"
    >
      {{ leftLabel }}
    </span>
    <div class="w-px h-4 bg-n-weak shrink-0" />
    <MultiselectDropdown
      chevron-only
      compact
      :disabled="isAssigning"
      :options="agentsList"
      :selected-item="assignedAgent"
      :multiselector-title="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.AGENT')"
      :multiselector-placeholder="$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
      :no-search-result="
        $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.AGENT')
      "
      :input-placeholder="
        $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.AGENT')
      "
      @select="onClickAssignAgent"
    />
  </div>

  <!-- Sidebar / full: unchanged -->
  <div v-else class="flex items-center gap-1 min-w-0 w-full">
    <NextButton
      v-if="showSelfAssignButton && showSelfAssign"
      link
      xs
      class="!gap-1 flex-shrink-0"
      :disabled="isAssigning"
      :label="$t('CONVERSATION_SIDEBAR.SELF_ASSIGN')"
      @click="onSelfAssign"
    />
    <div class="min-w-0 w-full">
      <MultiselectDropdown
        :borderless="borderless"
        :disabled="isAssigning"
        :options="agentsList"
        :selected-item="assignedAgent"
        :multiselector-title="$t('AGENT_MGMT.MULTI_SELECTOR.TITLE.AGENT')"
        :multiselector-placeholder="$t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')"
        :no-search-result="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.AGENT')
        "
        :input-placeholder="
          $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.AGENT')
        "
        @select="onClickAssignAgent"
      />
    </div>
  </div>
</template>
