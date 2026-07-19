<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { RESOLVED_LABEL_KEYS } from 'dashboard/composables/useStatusLabel';
import SectionLayout from './SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();
const selectedKey = ref('resolved');
const isSubmitting = ref(false);

watch(
  currentAccount,
  () => {
    const key = currentAccount.value?.settings?.resolved_label_key;
    selectedKey.value = RESOLVED_LABEL_KEYS.includes(key) ? key : 'resolved';
  },
  { deep: true, immediate: true }
);

const handleSubmit = async () => {
  try {
    isSubmitting.value = true;
    await updateAccount(
      { resolved_label_key: selectedKey.value },
      { silent: true }
    );
    useAlert(t('GENERAL_SETTINGS.FORM.RESOLVED_STATUS_LABEL.API.SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.RESOLVED_STATUS_LABEL.API.ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.RESOLVED_STATUS_LABEL.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.RESOLVED_STATUS_LABEL.NOTE')"
    with-border
  >
    <form class="grid gap-4" @submit.prevent="handleSubmit">
      <WithLabel
        :label="t('GENERAL_SETTINGS.FORM.RESOLVED_STATUS_LABEL.LABEL')"
      >
        <select v-model="selectedKey" class="!mb-0 text-sm w-full">
          <option
            v-for="key in RESOLVED_LABEL_KEYS"
            :key="key"
            :value="key"
          >
            {{ t(`CHAT_LIST.RESOLVED_STATUS_LABELS.${key}`) }}
          </option>
        </select>
      </WithLabel>
      <div>
        <NextButton
          blue
          type="submit"
          :is-loading="isSubmitting"
          :label="t('GENERAL_SETTINGS.FORM.RESOLVED_STATUS_LABEL.UPDATE_BUTTON')"
        />
      </div>
    </form>
  </SectionLayout>
</template>
