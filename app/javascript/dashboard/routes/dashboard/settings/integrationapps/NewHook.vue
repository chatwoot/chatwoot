<template>
  <div class="column content-box">
    <woot-modal-header
      :header-title="integration.name"
      :header-content="integration.description"
    />
    <formulate-form
      #default="{ hasErrors }"
      v-model="values"
      @submit="submitForm"
    >
      <formulate-input
        v-for="item in formItems"
        :key="item.name"
        v-bind="item"
      />
      <formulate-input
        v-if="isHookTypeInbox"
        :options="inboxes"
        type="select"
        name="inbox"
        :placeholder="$t('INTEGRATION_APPS.ADD.FORM.INBOX.LABEL')"
        :label="$t('INTEGRATION_APPS.ADD.FORM.INBOX.PLACEHOLDER')"
        validation="required"
        validation-name="Inbox"
      />
      <div class="modal-footer">
        <woot-button :disabled="hasErrors" :loading="uiFlags.isCreatingHook">
          {{ $t('INTEGRATION_APPS.ADD.FORM.SUBMIT') }}
        </woot-button>
        <woot-button class="button clear" @click.prevent="onClose">
          {{ $t('INTEGRATION_APPS.ADD.FORM.CANCEL') }}
        </woot-button>
      </div>
    </formulate-form>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import hookMixin from './hookMixin';

export default {
  mixins: [alertMixin, hookMixin],
  props: {
    integration: {
      type: Object,
      default: () => ({}),
    },
  },
  data() {
    return {
      endPoint: '',
      alertMessage: '',
      values: {},
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'integrations/getUIFlags',
      websiteInboxes: 'inboxes/getWebsiteInboxes',
    }),
    inboxes() {
      return this.websiteInboxes
        .filter(inbox => {
          if (!this.isIntegrationDialogflow) {
            return true;
          }
          return !this.connectedDialogflowInboxIds.includes(inbox.id);
        })
        .map(inbox => ({ label: inbox.name, value: inbox.id }));
    },

    connectedDialogflowInboxIds() {
      if (!this.isIntegrationDialogflow) {
        return [];
      }
      return this.integration.hooks.map(hook => hook.inbox?.id);
    },
    formItems() {
      return this.integration.settings_form_schema;
    },
    isIntegrationDialogflow() {
      return this.integration.id === 'dialogflow';
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    buildHookPayload() {
      const hookPayload = {
        app_id: this.integration.id,
        settings: {},
      };

      hookPayload.settings = Object.keys(this.values).reduce((acc, key) => {
        if (key !== 'inbox') {
          acc[key] = this.values[key];
        }
        return acc;
      }, {});

      this.formItems.forEach(item => {
        if (item.validation.includes('JSON')) {
          hookPayload.settings[item.name] = JSON.parse(
            hookPayload.settings[item.name]
          );
        }
      });

      if (this.isHookTypeInbox && this.values.inbox) {
        hookPayload.inbox_id = this.values.inbox;
      }

      return hookPayload;
    },
    async submitForm() {
      try {
        await this.$store.dispatch(
          'integrations/createHook',
          this.buildHookPayload()
        );
        this.alertMessage = this.$t('INTEGRATION_APPS.ADD.API.SUCCESS_MESSAGE');
        this.onClose();
      } catch (error) {
        const errorMessage = error?.response?.data?.message;
        this.alertMessage =
          errorMessage || this.$t('INTEGRATION_APPS.ADD.API.ERROR_MESSAGE');
      } finally {
        this.showAlert(this.alertMessage);
      }
    },
  },
};
</script>
