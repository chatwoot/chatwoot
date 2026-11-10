<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAutomationRoute } from 'dashboard/composables/useAutomationRoute';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SlaForm from './SlaForm.vue';

const emit = defineEmits(['close']);

const { t } = useI18n();
const store = useStore();
const { createAutomation } = useAutomationRoute();

const createdSla = ref(null);

const onClose = () => emit('close');

const addSLA = async payload => {
  try {
    createdSla.value = await store.dispatch('sla/create', payload);
  } catch (error) {
    useAlert(error.message || t('SLA.ADD.API.ERROR_MESSAGE'));
  }
};
</script>

<template>
  <div v-if="createdSla" class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('SLA.ADD.SUCCESS.TITLE')"
      :header-content="$t('SLA.ADD.SUCCESS.DESC')"
    />
    <div class="flex items-center justify-end w-full gap-2 px-8 pt-8 pb-8">
      <NextButton
        faded
        slate
        :label="$t('SLA.ADD.SUCCESS.LATER')"
        @click="onClose"
      />
      <NextButton
        :label="$t('SLA.ADD.SUCCESS.CREATE_AUTOMATION')"
        @click="createAutomation({ slaPolicyId: createdSla.id })"
      />
    </div>
  </div>
  <div v-else class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('SLA.ADD.TITLE')"
      :header-content="$t('SLA.ADD.DESC')"
    />
    <SlaForm
      :submit-label="$t('SLA.FORM.CREATE')"
      @submit-sla="addSLA"
      @close="onClose"
    />
  </div>
</template>
