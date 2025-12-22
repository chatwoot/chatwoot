<script>
import { useAlert } from 'dashboard/composables';
import { useBranding } from 'shared/composables/useBranding';
import { mapGetters } from 'vuex';
import WebhookForm from './WebhookForm.vue';

export default {
  components: { WebhookForm },
  props: {
    onClose: {
      type: Function,
      required: true,
    },
  },
  setup() {
    const { replaceInstallationName } = useBranding();
    return {
      replaceInstallationName,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'webhooks/getUIFlags',
    }),
  },
  methods: {
    async onSubmit(webhook) {
      try {
        await this.$store.dispatch('webhooks/create', { webhook });
        useAlert(
          this.$t('INTEGRATION_SETTINGS.WEBHOOK.ADD.API.SUCCESS_MESSAGE')
        );
        this.onClose();
      } catch (error) {
        const message =
          error.response.data.message ||
          this.$t('INTEGRATION_SETTINGS.WEBHOOK.EDIT.API.ERROR_MESSAGE');
        useAlert(message);
      }
    },
  },
};
</script>

<template>
  <div class="h-auto overflow-auto flex flex-col">
    <woot-modal-header
      :header-title="$t('INTEGRATION_SETTINGS.WEBHOOK.ADD.TITLE')"
      :header-content="
        replaceInstallationName($t('INTEGRATION_SETTINGS.WEBHOOK.FORM.DESC'))
      "
    />
    <WebhookForm
      :is-submitting="uiFlags.creatingItem"
      :submit-label="$t('INTEGRATION_SETTINGS.WEBHOOK.FORM.ADD_SUBMIT')"
      @submit="onSubmit"
      @cancel="onClose"
    />
  </div>
</template>
