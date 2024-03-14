<template>
  <div class="h-auto overflow-auto flex flex-col">
    <woot-modal-header :header-title="pageTitle" />
    <sla-form
      :submit-label="$t('SLA.FORM.EDIT')"
      :selected-response="selectedResponse"
      @submit="editSLA"
      @close="onClose"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import validationMixin from './validationMixin';
import validations from './validations';
import SlaForm from './SlaForm.vue';

export default {
  components: {
    SlaForm,
  },
  mixins: [alertMixin, validationMixin],
  props: {
    selectedResponse: {
      type: Object,
      default: () => {},
    },
  },
  validations,
  computed: {
    ...mapGetters({
      uiFlags: 'sla/getUIFlags',
    }),
    pageTitle() {
      return `${this.$t('SLA.EDIT.TITLE')} - ${this.selectedResponse.name}`;
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    async editSLA(payload) {
      try {
        await this.$store.dispatch('sla/update', {
          id: this.selectedResponse.id,
          ...payload,
        });
        this.showAlert(this.$t('SLA.EDIT.API.SUCCESS_MESSAGE'));
        this.onClose();
      } catch (error) {
        const errorMessage =
          error.message || this.$t('SLA.EDIT.API.ERROR_MESSAGE');
        this.showAlert(errorMessage);
      }
    },
  },
};
</script>
