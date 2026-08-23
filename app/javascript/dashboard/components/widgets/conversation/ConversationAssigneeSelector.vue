<script setup>
import { computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useToggle } from '@vueuse/core';
import MultiselectDropdownItems from 'shared/components/ui/MultiselectDropdownItems.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Avatar from 'next/avatar/Avatar.vue';
import { useConversationAssignee } from 'dashboard/composables/useConversationAssignee';
import { useI18n } from 'vue-i18n';
import { OnClickOutside } from '@vueuse/components';

defineProps({
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
  isAssigning,
  onClickAssignAgent,
  onSelfAssign,
} = useConversationAssignee();

const [showMenu, toggleMenu] = useToggle(false);

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

const canSelfAssign = computed(() => showSelfAssign.value);

const displayName = computed(
  () => assignedAgent.value?.name || t('AGENT_MGMT.MULTI_SELECTOR.PLACEHOLDER')
);

const closeMenu = () => toggleMenu(false);

const onTriggerClick = () => {
  if (isAssigning.value) return;
  toggleMenu();
};

const onSelectAgent = agent => {
  onClickAssignAgent(agent);
  closeMenu();
};
</script>

<template>
  <OnClickOutside @trigger="closeMenu">
    <div
      v-tooltip="t('CONVERSATION.HEADER.ASSIGNEE')"
      class="relative flex items-center h-8 min-w-0 max-w-[10rem] rounded-lg outline outline-1 outline-n-weak bg-n-background shrink-0"
    >
      <button
        v-if="showSelfAssignButton && canSelfAssign"
        type="button"
        class="flex-1 min-w-0 h-full px-2.5 text-left text-sm font-medium text-n-blue-11 truncate rounded-none border-0 bg-transparent hover:bg-n-alpha-2 disabled:opacity-50"
        :disabled="isAssigning"
        @click.stop="onSelfAssign"
      >
        {{ t('CONVERSATION_SIDEBAR.SELF_ASSIGN') }}
      </button>
      <button
        v-else
        type="button"
        class="flex flex-1 min-w-0 items-center gap-1.5 h-full px-2 text-left border-0 bg-transparent hover:bg-n-alpha-2 rounded-none"
        :disabled="isAssigning"
        @click="onTriggerClick"
      >
        <Avatar
          v-if="assignedAgent"
          :name="assignedAgent.name"
          :src="assignedAgent.thumbnail"
          :status="assignedAgent.availability_status"
          :size="18"
          hide-offline-status
          rounded-full
          class="shrink-0"
        />
        <span
          class="min-w-0 text-sm text-n-slate-12 truncate"
          :title="displayName"
        >
          {{ displayName }}
        </span>
      </button>
      <div class="w-px h-4 bg-n-weak shrink-0" />
      <NextButton
        color="slate"
        variant="ghost"
        size="sm"
        :disabled="isAssigning"
        :icon="showMenu ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
        class="!w-8 !h-8 !min-w-8 !rounded-none !outline-transparent"
        @click.stop="onTriggerClick"
      />
      <div
        v-if="showMenu"
        class="box-border border rounded-lg bg-n-alpha-3 backdrop-blur-[100px] absolute shadow-lg border-n-strong dark:border-n-strong p-2 z-[9999] top-9 ltr:right-0 rtl:left-0 min-w-[16rem] w-max"
      >
        <div class="flex items-center justify-between mb-1">
          <h4
            class="m-0 overflow-hidden text-sm text-n-slate-11 whitespace-nowrap text-ellipsis"
          >
            {{ $t('AGENT_MGMT.MULTI_SELECTOR.TITLE.AGENT') }}
          </h4>
          <NextButton
            variant="ghost"
            color="slate"
            size="xs"
            icon="i-lucide-x"
            @click="closeMenu"
          />
        </div>
        <MultiselectDropdownItems
          :options="agentsList"
          :selected-items="assignedAgent ? [assignedAgent] : []"
          has-thumbnail
          :input-placeholder="
            $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.PLACEHOLDER.AGENT')
          "
          :no-search-result="
            $t('AGENT_MGMT.MULTI_SELECTOR.SEARCH.NO_RESULTS.AGENT')
          "
          @select="onSelectAgent"
        />
      </div>
    </div>
  </OnClickOutside>
</template>
