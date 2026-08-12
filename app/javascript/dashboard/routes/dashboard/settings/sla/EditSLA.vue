<script>
import { useAlert } from 'dashboard/composables';
import SlaForm from './SlaForm.vue';

export default {
  components: {
    SlaForm,
  },
  props: {
    selectedResponse: {
      type: Object,
      default: () => ({}),
    },
  },
  methods: {
    open(sla) {
      this.$refs.formRef.open(sla);
    },
    close() {
      this.$refs.formRef.close();
    },
    async editSLA(payload) {
      try {
        await this.$store.dispatch('sla/update', {
          id: this.selectedResponse.id,
          ...payload,
        });
        useAlert(this.$t('SLA.EDIT.API.SUCCESS_MESSAGE'));
        this.close();
      } catch (error) {
        const errorMessage =
          error.message || this.$t('SLA.EDIT.API.ERROR_MESSAGE');
        useAlert(errorMessage);
      }
    },
  },
};
</script>

<template>
  <SlaForm ref="formRef" mode="edit" @submit-sla="editSLA" />
</template>
