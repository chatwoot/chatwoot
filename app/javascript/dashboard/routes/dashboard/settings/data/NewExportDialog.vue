<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Banner from 'dashboard/components-next/banner/Banner.vue';
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
    :description="$t('DATA_EXPORTS.DESCRIPTION')"
    :confirm-button-label="$t('DATA_EXPORTS.START')"
    :is-loading="isCreating"
    :disable-confirm-button="isCreating"
    overflow-y-auto
    @confirm="createExport"
    @close="emit('close')"
  >
    <div class="flex flex-col gap-4">
      <div
        class="flex items-center gap-3 rounded-xl border border-n-weak bg-n-solid-1 p-4"
      >
        <span
          class="flex size-10 shrink-0 items-center justify-center rounded-lg bg-n-alpha-2"
        >
          <Icon icon="i-lucide-file-output" class="size-5 text-n-slate-11" />
        </span>
        <div class="flex min-w-0 flex-col gap-1">
          <span class="text-heading-3 text-n-slate-12">{{ scope }}</span>
          <span class="text-label-small text-n-slate-11">{{
            $t('DATA_EXPORTS.FILE_FORMAT')
          }}</span>
        </div>
      </div>
      <Banner>{{ $t('DATA_EXPORTS.NOTIFICATION') }}</Banner>
    </div>
  </Dialog>
</template>
