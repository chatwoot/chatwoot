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
import alertMixin from 'shared/mixins/alertMixin';
import { mapGetters } from 'vuex';
import SlaForm from './SlaForm.vue';

export default {
  components: {
    SlaForm,
  },
  mixins: [alertMixin],
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
        this.showAlert(this.$t('SLA.ADD.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        const errorMessage =
          error.message || this.$t('SLA.ADD.API.ERROR_MESSAGE');
        this.showAlert(errorMessage);
      }
    },
  },
};
</script>
