<script>
import { useAlert } from 'dashboard/composables';
import SlaForm from './SlaForm.vue';

export default {
  components: {
    SlaForm,
  },
  methods: {
    open() {
      this.$refs.formRef.open();
    },
    close() {
      this.$refs.formRef.close();
    },
    async addSLA(payload) {
      try {
        await this.$store.dispatch('sla/create', payload);
        useAlert(this.$t('SLA.ADD.API.SUCCESS_MESSAGE'));
        this.close();
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
  <SlaForm ref="formRef" mode="create" @submit-sla="addSLA" />
</template>
