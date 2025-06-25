<template>
  <div class="column content-box">
    <woot-modal-header
      :header-title="$t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.TITLE')"
    />
    <webhook-form
      :value="value"
      :is-submitting="uiFlags.updatingItem"
      :submit-label="$t('INTEGRATION_SETTINGS.WEBHOOK.FORM.EDIT_SUBMIT')"
      @submit="onSubmit"
      @cancel="onClose"
    />
  </div>
</template>

<script>
import alertMixin from 'shared/mixins/alertMixin';
import { mapGetters } from 'vuex';
import WebhookForm from './WebhookForm.vue';

export default {
  components: { WebhookForm },
  mixins: [alertMixin],
  props: {
    value: {
      type: Object,
      required: true,
    },
    id: {
      type: [Number, String],
      required: true,
    },
    onClose: {
      type: Function,
      required: true,
    },
  },
  computed: {
    ...mapGetters({ uiFlags: 'webhooks/getUIFlags' }),
  },
  methods: {
    async onSubmit(webhook) {
      try {
        await this.$store.dispatch('webhooks/update', {
          webhook,
          id: this.id,
        });
        this.showAlert(
          this.$t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.API.SUCCESS_MESSAGE')
        );
        this.onClose();
      } catch (error) {
        const alertMessage =
          error.response.data.message ||
          this.$t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.API.ERROR_MESSAGE');
        this.showAlert(alertMessage);
      }
    },
  },
};
</script>
