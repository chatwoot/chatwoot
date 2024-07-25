<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('SLA.ADD.TITLE')"
      :header-content="$t('SLA.ADD.DESC')"
    />
    <sla-form
      :submit-label="$t('SLA.FORM.CREATE')"
      @submit="addSLA"
      @close="onClose"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import SlaForm from './SlaForm.vue';

export default {
  components: {
    SlaForm,
  },
  computed: {
    ...mapGetters({
      uiFlags: 'sla/getUIFlags',
    }),
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    async addSLA(payload) {
      try {
        await this.$store.dispatch('sla/create', payload);
        useAlert(this.$t('SLA.ADD.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        const errorMessage =
          error.message || this.$t('SLA.ADD.API.ERROR_MESSAGE');
        useAlert(errorMessage);
      }
    },
  },
};
</script>
