<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const emit = defineEmits(['delete']);

const FILTER_TYPE_CONTACT = 'contact';

const { t } = useI18n();

const uiFlags = useMapGetter('customViews/getUIFlags');
const isDeleting = computed(() => uiFlags.value.isDeleting);

const dialogRef = ref(null);

const handleDialogConfirm = async () => {
  emit('delete', {
    filterType: FILTER_TYPE_CONTACT,
  });
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    type="alert"
    :title="t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.DELETE_SEGMENT.TITLE')"
    :description="
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.DELETE_SEGMENT.DESCRIPTION')
    "
    :confirm-button-label="
      t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.DELETE_SEGMENT.CONFIRM')
    "
    :is-loading="isDeleting"
    :disable-confirm-button="isDeleting"
    @confirm="handleDialogConfirm"
  />
</template>
