<script setup>
import { computed, ref } from 'vue';
import CopilotContainer from '../../copilot/CopilotContainer.vue';
import ContactPanel from 'dashboard/routes/dashboard/conversation/ContactPanel.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { FEATURE_FLAGS } from '../../../featureFlags';

const props = defineProps({
  currentChat: {
    required: true,
    type: Object,
  },
});

const emit = defineEmits(['toggleContactPanel']);

const { t } = useI18n();

const channelType = computed(() => props.currentChat?.meta?.channel || '');

const CONTACT_TABS_OPTIONS = [
  { key: 'CONTACT', value: 'contact' },
  { key: 'COPILOT', value: 'copilot' },
];

const tabs = computed(() => {
  return CONTACT_TABS_OPTIONS.map(tab => ({
    label: t(`CONVERSATION.SIDEBAR.${tab.key}`),
    value: tab.value,
  }));
});
const activeTab = ref(0);
const toggleContactPanel = () => {
  emit('toggleContactPanel');
};

const handleTabChange = selectedTab => {
  activeTab.value = tabs.value.findIndex(
    tabItem => tabItem.value === selectedTab.value
  );
};
const currentAccountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const showCopilotTab = computed(() =>
  isFeatureEnabledonAccount.value(currentAccountId.value, FEATURE_FLAGS.CAPTAIN)
);
</script>

<template>
  <div
    class="ltr:border-l rtl:border-r border-n-weak h-full overflow-hidden z-10 w-80 min-w-80 2xl:min-w-96 2xl:w-96 flex flex-col bg-n-background"
  >
    <div v-if="showCopilotTab" class="p-2">
      <TabBar
        :tabs="tabs"
        :initial-active-tab="activeTab"
        class="w-full [&>button]:w-full"
        @tab-changed="handleTabChange"
      />
    </div>
    <div class="flex flex-1 overflow-auto">
      <ContactPanel
        v-if="!activeTab"
        :conversation-id="currentChat.id"
        :inbox-id="currentChat.inbox_id"
        :on-toggle="toggleContactPanel"
      />
      <CopilotContainer
        v-else-if="activeTab === 1 && showCopilotTab"
        :key="currentChat.id"
        :conversation-inbox-type="channelType"
        :conversation-id="currentChat.id"
        class="flex-1"
      />
    </div>
  </div>
</template>
