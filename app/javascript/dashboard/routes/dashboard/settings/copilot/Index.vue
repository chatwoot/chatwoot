<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCaptain } from 'dashboard/composables/useCaptain';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import CaptainPaywall from 'next/captain/pageComponents/Paywall.vue';
import ToolsTab from './components/ToolsTab.vue';
import KnowledgeTab from './components/KnowledgeTab.vue';

const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();
const { captainEnabled } = useCaptain();

const TABS = { GENERAL: 'general', TOOLS: 'tools', KNOWLEDGE: 'knowledge' };
const tabs = computed(() => [
  { key: TABS.GENERAL, label: t('COPILOT_SETTINGS.TABS.GENERAL') },
  { key: TABS.TOOLS, label: t('COPILOT_SETTINGS.TABS.TOOLS') },
  { key: TABS.KNOWLEDGE, label: t('COPILOT_SETTINGS.TABS.KNOWLEDGE') },
]);
const activeTab = ref(TABS.GENERAL);
const activeTabIndex = computed(() =>
  tabs.value.findIndex(tab => tab.key === activeTab.value)
);
const onTabChanged = tab => {
  activeTab.value = tab.key;
};

const copilotSettings = computed(
  () => currentAccount.value?.settings?.copilot || {}
);

// The account update replaces the whole copilot object, so every save sends all of it
const saveSettings = async changes => {
  try {
    await updateAccount(
      { copilot: { ...copilotSettings.value, ...changes } },
      { silent: true }
    );
    useAlert(t('COPILOT_SETTINGS.API.SUCCESS'));
  } catch {
    useAlert(t('COPILOT_SETTINGS.API.ERROR'));
  }
};

// Missing means on, so accounts that never saved this page keep the prompts
const showOnHome = computed({
  get: () => copilotSettings.value.show_on_home !== false,
  set: value => saveSettings({ show_on_home: value }),
});
</script>

<template>
  <SettingsLayout
    :is-loading="!currentAccount?.id"
    :loading-message="t('COPILOT_SETTINGS.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="t('COPILOT_SETTINGS.TITLE')"
        :description="t('COPILOT_SETTINGS.DESCRIPTION')"
      >
        <template v-if="captainEnabled" #tabs>
          <TabBar
            :tabs="tabs"
            :initial-active-tab="activeTabIndex"
            @tab-changed="onTabChanged"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <div v-if="captainEnabled" class="flex flex-col gap-6">
        <SettingsToggleSection
          v-if="activeTab === TABS.GENERAL"
          v-model="showOnHome"
          :header="t('COPILOT_SETTINGS.HOME_SCREEN.TITLE')"
          :description="t('COPILOT_SETTINGS.HOME_SCREEN.DESCRIPTION')"
        />
        <ToolsTab
          v-else-if="activeTab === TABS.TOOLS"
          :settings="copilotSettings"
          @manage-knowledge="activeTab = TABS.KNOWLEDGE"
        />
        <KnowledgeTab
          v-else
          :settings="copilotSettings"
          @update="saveSettings"
        />
      </div>
      <CaptainPaywall v-else />
    </template>
  </SettingsLayout>
</template>
