<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import SectionLayout from './components/SectionLayout.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';

const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();

const autoLabelEnabled = ref(false);
const autoTeamEnabled = ref(false);
const messageThreshold = ref(3);

// Watch for account changes and update local state reactively
watch(
  currentAccount,
  () => {
    const {
      auto_label_enabled,
      auto_team_enabled,
      auto_label_message_threshold,
    } = currentAccount.value?.settings || {};
    autoLabelEnabled.value = auto_label_enabled || false;
    autoTeamEnabled.value = auto_team_enabled || false;
    messageThreshold.value = auto_label_message_threshold || 3;
  },
  { deep: true, immediate: true }
);

const updateSettings = async () => {
  try {
    await updateAccount(
      {
        auto_label_enabled: autoLabelEnabled.value,
        auto_team_enabled: autoTeamEnabled.value,
        auto_label_message_threshold: messageThreshold.value,
      },
      { silent: true }
    );
    useAlert(t('LABEL_MGMT.AUTO_CLASSIFICATION.UPDATE_SUCCESS'));
  } catch (error) {
    useAlert(t('LABEL_MGMT.AUTO_CLASSIFICATION.UPDATE_FAILED'));
  }
};

const handleLabelToggle = () => {
  updateSettings();
};

const handleTeamToggle = () => {
  updateSettings();
};

const handleThresholdChange = () => {
  if (autoLabelEnabled.value || autoTeamEnabled.value) {
    updateSettings();
  }
};
</script>

<template>
  <div class="space-y-4">
    <!-- Auto Label Section -->
    <SectionLayout
      :title="t('LABEL_MGMT.AUTO_CLASSIFICATION.LABEL_TITLE')"
      :description="t('LABEL_MGMT.AUTO_CLASSIFICATION.LABEL_DESCRIPTION')"
      :hide-content="!autoLabelEnabled"
      with-border
    >
      <template #headerActions>
        <div class="flex justify-end">
          <Switch v-model="autoLabelEnabled" @change="handleLabelToggle" />
        </div>
      </template>

      <div class="grid gap-5">
        <WithLabel
          :label="t('LABEL_MGMT.AUTO_CLASSIFICATION.THRESHOLD_LABEL')"
          :help-message="t('LABEL_MGMT.AUTO_CLASSIFICATION.THRESHOLD_HINT')"
        >
          <input
            v-model.number="messageThreshold"
            type="number"
            min="1"
            max="10"
            class="block w-24 rounded-md border-n-weak bg-n-solid-1 text-n-slate-12 shadow-sm focus:border-n-brand focus:ring-n-brand sm:text-sm"
            @change="handleThresholdChange"
          />
        </WithLabel>
      </div>
    </SectionLayout>

    <!-- Auto Team Section -->
    <SectionLayout
      :title="t('LABEL_MGMT.AUTO_CLASSIFICATION.TEAM_TITLE')"
      :description="t('LABEL_MGMT.AUTO_CLASSIFICATION.TEAM_DESCRIPTION')"
      :hide-content="!autoTeamEnabled"
      with-border
    >
      <template #headerActions>
        <div class="flex justify-end">
          <Switch v-model="autoTeamEnabled" @change="handleTeamToggle" />
        </div>
      </template>

      <div class="grid gap-5">
        <WithLabel
          :label="t('LABEL_MGMT.AUTO_CLASSIFICATION.THRESHOLD_LABEL')"
          :help-message="t('LABEL_MGMT.AUTO_CLASSIFICATION.THRESHOLD_HINT')"
        >
          <input
            v-model.number="messageThreshold"
            type="number"
            min="1"
            max="10"
            class="block w-24 rounded-md border-n-weak bg-n-solid-1 text-n-slate-12 shadow-sm focus:border-n-brand focus:ring-n-brand sm:text-sm"
            @change="handleThresholdChange"
          />
        </WithLabel>
      </div>
    </SectionLayout>
  </div>
</template>
