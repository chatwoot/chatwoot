<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import SectionLayout from './SectionLayout.vue';

const { t } = useI18n();
const handle = ref('');
const savedHandle = ref('');
const pushOnly = ref(false);
const savedPushOnly = ref(false);

const { currentAccount, updateAccount } = useAccount();

watch(
  currentAccount,
  () => {
    const customAttrs = currentAccount.value?.custom_attributes || {};
    const val = customAttrs.infinitepay_handle || '';
    handle.value = val;
    savedHandle.value = val;
    const pushOnlyValue = Boolean(customAttrs.infinitepay_push_only);
    pushOnly.value = pushOnlyValue;
    savedPushOnly.value = pushOnlyValue;
  },
  { deep: true, immediate: true }
);

const isSaving = ref(false);
const hasChanges = computed(() => {
  return handle.value.trim() !== savedHandle.value || pushOnly.value !== savedPushOnly.value;
});

const saveSettings = async () => {
  if (!hasChanges.value) return;
  isSaving.value = true;
  try {
    await updateAccount({
      infinitepay_handle: handle.value.trim(),
      infinitepay_push_only: pushOnly.value,
    });
    savedHandle.value = handle.value.trim();
    savedPushOnly.value = pushOnly.value;
    useAlert(t('GENERAL_SETTINGS.FORM.INFINITEPAY.API.SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.INFINITEPAY.API.ERROR'));
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.INFINITEPAY.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.INFINITEPAY.NOTE')"
    with-border
  >
    <div class="flex flex-col gap-3">
      <div class="flex gap-3 items-end">
        <label class="flex flex-col flex-1 gap-1">
          <span class="text-xs font-medium text-n-slate-11">
            {{ t('GENERAL_SETTINGS.FORM.INFINITEPAY.HANDLE_LABEL') }}
          </span>
          <input
            v-model="handle"
            type="text"
            :placeholder="t('GENERAL_SETTINGS.FORM.INFINITEPAY.HANDLE_PLACEHOLDER')"
            class="w-full px-3 py-2 text-sm border rounded-lg border-n-slate-6 bg-n-slate-1 text-n-slate-12 focus:border-n-blue-7 focus:outline-none"
          />
        </label>
        <button
          :disabled="isSaving || !hasChanges"
          class="px-4 py-2 text-sm font-medium text-white rounded-lg bg-n-blue-9 hover:bg-n-blue-10 disabled:opacity-50 disabled:cursor-not-allowed"
          @click="saveSettings"
        >
          {{ t('GENERAL_SETTINGS.SUBMIT') }}
        </button>
      </div>
      <label
        class="flex items-start justify-between gap-4 px-4 py-3 border rounded-lg border-n-slate-5 bg-n-slate-2"
      >
        <div class="flex flex-col gap-1">
          <span class="text-sm font-medium text-n-slate-12">
            {{ t('GENERAL_SETTINGS.FORM.INFINITEPAY.PUSH_ONLY_LABEL') }}
          </span>
          <span class="text-xs leading-5 text-n-slate-11">
            {{ t('GENERAL_SETTINGS.FORM.INFINITEPAY.PUSH_ONLY_NOTE') }}
          </span>
        </div>
        <input
          v-model="pushOnly"
          type="checkbox"
          class="w-4 h-4 mt-1 rounded border-n-slate-6 text-n-blue-9 focus:ring-n-blue-7"
        />
      </label>
      <div
        v-if="savedHandle"
        class="flex items-center gap-2 text-xs text-n-green-11"
      >
        <span class="inline-block w-2 h-2 rounded-full bg-n-green-9" />
        {{ t('GENERAL_SETTINGS.FORM.INFINITEPAY.CONFIGURED', { handle: savedHandle }) }}
      </div>
      <div
        v-if="savedPushOnly"
        class="text-xs text-n-slate-11"
      >
        {{ t('GENERAL_SETTINGS.FORM.INFINITEPAY.PUSH_ONLY_ENABLED') }}
      </div>
    </div>
  </SectionLayout>
</template>
