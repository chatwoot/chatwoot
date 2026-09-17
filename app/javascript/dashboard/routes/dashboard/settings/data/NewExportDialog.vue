<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import DataExportsAPI from 'dashboard/api/dataExports';

const props = defineProps({
  show: { type: Boolean, default: false },
  selection: { type: Object, default: () => ({}) },
});
const emit = defineEmits(['close', 'created']);
const { t } = useI18n();
const dialogRef = ref(null);
const isCreating = ref(false);
const scope = computed(
  () =>
    props.selection.scope_name ||
    props.selection.label ||
    t('DATA_EXPORTS.ALL_CONTACTS')
);
watch(
  () => props.show,
  show => {
    if (show) dialogRef.value?.open();
    else dialogRef.value?.close();
  }
);
const createExport = async () => {
  isCreating.value = true;
  try {
    const response = await DataExportsAPI.create(props.selection);
    emit('created', response.data.id);
  } catch (error) {
    useAlert(error?.response?.data?.message || t('DATA_EXPORTS.ERROR'));
  } finally {
    isCreating.value = false;
  }
};
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="$t('DATA_EXPORTS.NEW')"
    :confirm-button-label="$t('DATA_EXPORTS.START')"
    :is-loading="isCreating"
    :disable-confirm-button="isCreating"
    @confirm="createExport"
    @close="emit('close')"
  >
    <div class="flex flex-col gap-3 text-body-main text-n-slate-11">
      <p>{{ $t('DATA_EXPORTS.SCOPE', { scope }) }}</p>
      <p>{{ $t('DATA_EXPORTS.DESCRIPTION') }}</p>
    </div>
  </Dialog>
</template>
