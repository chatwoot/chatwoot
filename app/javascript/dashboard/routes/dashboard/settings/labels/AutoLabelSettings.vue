<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import SectionLayout from '../account/components/SectionLayout.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';

const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();

const autoLabelEnabled = ref(false);
const messageThreshold = ref(3);

// Watch for account changes and update local state reactively
watch(
  currentAccount,
  () => {
    const { auto_label_enabled, auto_label_message_threshold } =
      currentAccount.value?.settings || {};
    autoLabelEnabled.value = auto_label_enabled || false;
    messageThreshold.value = auto_label_message_threshold || 3;
  },
  { deep: true, immediate: true }
);

const updateSettings = async () => {
  try {
    await updateAccount(
      {
        auto_label_enabled: autoLabelEnabled.value,
        auto_label_message_threshold: messageThreshold.value,
      },
      { silent: true }
    );
    useAlert(t('LABEL_MGMT.AUTO_LABEL.UPDATE_SUCCESS'));
  } catch (error) {
    useAlert(t('LABEL_MGMT.AUTO_LABEL.UPDATE_FAILED'));
  }
};

const handleToggle = () => {
  updateSettings();
};

const handleThresholdChange = () => {
  if (autoLabelEnabled.value) {
    updateSettings();
  }
};
</script>

<template>
  <SectionLayout
    :title="t('LABEL_MGMT.AUTO_LABEL.TITLE')"
    :description="t('LABEL_MGMT.AUTO_LABEL.DESCRIPTION')"
    :hide-content="!autoLabelEnabled"
    with-border
  >
    <template #headerActions>
      <div class="flex justify-end">
        <Switch v-model="autoLabelEnabled" @change="handleToggle" />
      </div>
    </template>

    <div class="grid gap-5">
      <WithLabel
        :label="t('LABEL_MGMT.AUTO_LABEL.THRESHOLD_LABEL')"
        :help-message="t('LABEL_MGMT.AUTO_LABEL.THRESHOLD_HINT')"
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

      <div
        class="rounded-xl border border-n-weak bg-n-alpha-3 p-3 text-sm text-n-slate-11"
      >
        <p>{{ t('LABEL_MGMT.AUTO_LABEL.INFO_MESSAGE') }}</p>
      </div>
    </div>
  </SectionLayout>
</template>
