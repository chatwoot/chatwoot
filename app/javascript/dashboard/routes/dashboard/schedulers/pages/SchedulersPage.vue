<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import SchedulerLayout from 'dashboard/components-next/Schedulers/SchedulerLayout.vue';
import SchedulerList from 'dashboard/components-next/Schedulers/Pages/SchedulerPage/SchedulerList.vue';
import SchedulerDialog from 'dashboard/components-next/Schedulers/Pages/SchedulerPage/SchedulerDialog.vue';
import ConfirmDeleteSchedulerDialog from 'dashboard/components-next/Schedulers/Pages/SchedulerPage/ConfirmDeleteSchedulerDialog.vue';
import SchedulerEmptyState from 'dashboard/components-next/Schedulers/EmptyState/SchedulerEmptyState.vue';

const { t } = useI18n();
const getters = useStoreGetters();

const selectedScheduler = ref(null);
const [showCreateDialog, toggleCreateDialog] = useToggle();

const uiFlags = useMapGetter('schedulers/getUIFlags');
const isFetching = computed(() => uiFlags.value.isFetching);

const schedulers = computed(() => getters['schedulers/getSchedulers'].value);
const hasNoSchedulers = computed(
  () => schedulers.value?.length === 0 && !isFetching.value
);

const confirmDeleteDialogRef = ref(null);

const handleDelete = scheduler => {
  selectedScheduler.value = scheduler;
  confirmDeleteDialogRef.value.dialogRef.open();
};
</script>

<template>
  <SchedulerLayout
    :header-title="t('SCHEDULER.HEADER_TITLE')"
    :button-label="t('SCHEDULER.NEW_SCHEDULER')"
    @click="toggleCreateDialog()"
    @close="toggleCreateDialog(false)"
  >
    <template #action>
      <SchedulerDialog
        v-if="showCreateDialog"
        @close="toggleCreateDialog(false)"
      />
    </template>
    <div
      v-if="isFetching"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <SchedulerList
      v-else-if="!hasNoSchedulers"
      :schedulers="schedulers"
      @delete="handleDelete"
    />
    <SchedulerEmptyState
      v-else
      :title="t('SCHEDULER.EMPTY_STATE.TITLE')"
      :subtitle="t('SCHEDULER.EMPTY_STATE.SUBTITLE')"
      class="pt-14"
    />
    <ConfirmDeleteSchedulerDialog
      ref="confirmDeleteDialogRef"
      :selected-scheduler="selectedScheduler"
    />
  </SchedulerLayout>
</template>
