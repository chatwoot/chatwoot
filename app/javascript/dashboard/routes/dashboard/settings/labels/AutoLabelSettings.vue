<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';

const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();

const autoLabelEnabled = ref(false);
const messageThreshold = ref(3);
const isUpdating = ref(false);

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
  isUpdating.value = true;
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
  } finally {
    isUpdating.value = false;
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
  <div class="mb-6 rounded-lg border border-slate-200 bg-white p-6">
    <div class="mb-4">
      <h3 class="text-lg font-semibold text-slate-900">
        {{ t('LABEL_MGMT.AUTO_LABEL.TITLE') }}
      </h3>
      <p class="mt-1 text-sm text-slate-600">
        {{ t('LABEL_MGMT.AUTO_LABEL.DESCRIPTION') }}
      </p>
    </div>

    <!-- Toggle Switch -->
    <div class="flex items-center">
      <label class="relative inline-flex cursor-pointer items-center">
        <input
          v-model="autoLabelEnabled"
          type="checkbox"
          class="peer sr-only"
          :disabled="isUpdating"
          @change="handleToggle"
        />
        <div
          class="peer h-6 w-11 rounded-full bg-slate-200 after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:border after:border-slate-300 after:bg-white after:transition-all after:content-[''] peer-checked:bg-woot-500 peer-checked:after:translate-x-full peer-checked:after:border-white peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-woot-300 peer-disabled:opacity-50"
        />
        <span class="ml-3 text-sm font-medium text-slate-900">
          {{ t('LABEL_MGMT.AUTO_LABEL.ENABLE') }}
        </span>
      </label>
    </div>

    <!-- Threshold Configuration -->
    <div v-if="autoLabelEnabled" class="mt-4 border-t border-slate-200 pt-4">
      <label
        for="message-threshold"
        class="block text-sm font-medium text-slate-700"
      >
        {{ t('LABEL_MGMT.AUTO_LABEL.THRESHOLD_LABEL') }}
      </label>
      <div class="mt-2 flex items-center gap-4">
        <input
          id="message-threshold"
          v-model.number="messageThreshold"
          type="number"
          min="1"
          max="10"
          class="block w-24 rounded-md border-slate-300 shadow-sm focus:border-woot-500 focus:ring-woot-500 sm:text-sm"
          :disabled="isUpdating"
          @change="handleThresholdChange"
        />
        <span class="text-sm text-slate-600">
          {{ t('LABEL_MGMT.AUTO_LABEL.THRESHOLD_HINT') }}
        </span>
      </div>
    </div>

    <!-- Info Message -->
    <div v-if="autoLabelEnabled" class="mt-4 rounded-md bg-blue-50 p-3">
      <div class="flex">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          class="h-5 w-5 text-blue-400"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
          />
        </svg>
        <p class="ml-3 text-sm text-blue-700">
          {{ t('LABEL_MGMT.AUTO_LABEL.INFO_MESSAGE') }}
        </p>
      </div>
    </div>
  </div>
</template>
