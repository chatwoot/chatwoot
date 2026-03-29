<script setup>
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';

import SchedulerForm from './SchedulerForm.vue';

const emit = defineEmits(['close']);
const { t } = useI18n();
const store = useStore();

const handleSubmit = async schedulerDetails => {
  try {
    await store.dispatch('schedulers/create', schedulerDetails);
    useAlert(t('SCHEDULER.CREATE.SUCCESS_MESSAGE'));
    emit('close');
  } catch (error) {
    useAlert(t('SCHEDULER.CREATE.ERROR_MESSAGE'));
  }
};

const handleClose = () => emit('close');
</script>

<template>
  <div
    class="w-[25rem] z-50 min-w-0 absolute top-10 ltr:right-0 rtl:left-0 bg-n-alpha-3 backdrop-blur-[100px] rounded-xl border border-n-weak shadow-md max-h-[80vh] overflow-y-auto"
  >
    <div class="p-6 flex flex-col gap-6">
      <h3 class="text-base font-medium text-n-slate-12 flex-shrink-0">
        {{ t('SCHEDULER.CREATE.TITLE') }}
      </h3>
      <SchedulerForm @submit="handleSubmit" @cancel="handleClose" />
    </div>
  </div>
</template>
