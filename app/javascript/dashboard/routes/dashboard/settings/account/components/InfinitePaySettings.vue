<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import SectionLayout from './SectionLayout.vue';

const { t } = useI18n();
const handle = ref('');
const savedHandle = ref('');

const { currentAccount, updateAccount } = useAccount();

watch(
  currentAccount,
  () => {
    const customAttrs = currentAccount.value?.custom_attributes || {};
    const val = customAttrs.infinitepay_handle || '';
    handle.value = val;
    savedHandle.value = val;
  },
  { deep: true, immediate: true }
);

const isSaving = ref(false);
const hasChanges = computed(() => handle.value.trim() !== savedHandle.value);

const saveHandle = async () => {
  if (!hasChanges.value) return;
  isSaving.value = true;
  try {
    await updateAccount({ infinitepay_handle: handle.value.trim() });
    savedHandle.value = handle.value.trim();
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
          @click="saveHandle"
        >
          {{ t('GENERAL_SETTINGS.SUBMIT') }}
        </button>
      </div>
      <div
        v-if="savedHandle"
        class="flex items-center gap-2 text-xs text-n-green-11"
      >
        <span class="inline-block w-2 h-2 rounded-full bg-n-green-9" />
        {{ t('GENERAL_SETTINGS.FORM.INFINITEPAY.CONFIGURED', { handle: savedHandle }) }}
      </div>
    </div>
  </SectionLayout>
</template>
