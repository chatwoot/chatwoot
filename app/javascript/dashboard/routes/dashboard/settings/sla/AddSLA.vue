<script>
import { useAlert } from 'dashboard/composables';
import { useAutomationRoute } from 'dashboard/composables/useAutomationRoute';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SlaForm from './SlaForm.vue';

export default {
  components: {
    NextButton,
    SlaForm,
  },
  emits: ['close'],
  setup() {
    const { createAutomation } = useAutomationRoute();
    return { createAutomation };
  },
  data() {
    return {
      createdSla: null,
    };
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    async addSLA(payload) {
      try {
        this.createdSla = await this.$store.dispatch('sla/create', payload);
      } catch (error) {
        const errorMessage =
          error.message || this.$t('SLA.ADD.API.ERROR_MESSAGE');
        useAlert(errorMessage);
      }
    },
  },
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
