<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import Switch from 'next/switch/Switch.vue';

const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();
const isEnabled = ref(false);

watch(
  currentAccount,
  account => {
    isEnabled.value = account?.settings?.auto_translate === true;
  },
  { immediate: true, deep: true }
);

const toggleAutoTranslate = async () => {
  try {
    await updateAccount({ auto_translate: isEnabled.value }, { silent: true });
    useAlert(t('GENERAL_SETTINGS.FORM.AUTO_TRANSLATE.API.SUCCESS'));
  } catch {
    useAlert(t('GENERAL_SETTINGS.FORM.AUTO_TRANSLATE.API.ERROR'));
  }
};
</script>

<template>
  <div
    class="flex flex-col gap-2 items-start px-5 py-4 w-full outline-1 outline outline-n-container rounded-xl bg-n-solid-2"
  >
    <div class="flex justify-between items-center w-full">
      <h3 class="text-heading-2 text-n-slate-12">
        {{ t('GENERAL_SETTINGS.FORM.AUTO_TRANSLATE.TITLE') }}
      </h3>
      <Switch v-model="isEnabled" @change="toggleAutoTranslate" />
    </div>
    <p class="mb-0 text-body-para text-n-slate-11">
      {{ t('GENERAL_SETTINGS.FORM.AUTO_TRANSLATE.NOTE') }}
    </p>
  </div>
</template>
