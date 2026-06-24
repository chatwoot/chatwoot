<script setup>
import { onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { useConversationAssignee } from 'dashboard/composables/useConversationAssignee';
import { useI18n } from 'vue-i18n';

defineProps({
  compact: {
    type: Boolean,
    default: false,
  },
  showSelfAssignButton: {
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
</script>

<template>
  <div
    class="flex items-center gap-1"
    :class="compact ? 'min-w-[11rem] max-w-[14rem] shrink-0' : 'min-w-0 w-full'"
  >
    <NextButton
      v-if="showSelfAssignButton && showSelfAssign"
      link
      xs
      icon="i-lucide-arrow-right"
      class="!gap-1 flex-shrink-0"
      :label="$t('CONVERSATION_SIDEBAR.SELF_ASSIGN')"
      @click="onSelfAssign"
    />
    <div
      v-tooltip="compact ? t('CONVERSATION.HEADER.ASSIGNEE') : undefined"
      class="min-w-0"
      :class="compact ? 'w-full' : 'w-full'"
    >
      <MultiselectDropdown
        :compact="compact"
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
