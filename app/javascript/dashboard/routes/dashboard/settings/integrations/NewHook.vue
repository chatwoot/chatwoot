<!-- eslint-disable vue/v-slot-style -->
<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import hookMixin from './hookMixin';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import InboxFilter from 'dashboard/routes/dashboard/settings/reports/components/Filters/Inboxes.vue';

export default {
  components: {
    InboxFilter,
    WithLabel,
  },
  mixins: [hookMixin],
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
      inboxIds: [],
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'integrations/getUIFlags',
      dialogFlowEnabledInboxes: 'inboxes/dialogFlowEnabledInboxes',
    }),
    inboxes() {
      return this.dialogFlowEnabledInboxes
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
    isIntegrationCaptain() {
      return this.integration.id === 'captain';
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    setInboxes(selectedInboxes) {
      this.inboxIds = selectedInboxes.map(inbox => inbox.id);
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

      if (this.isIntegrationCaptain) {
        hookPayload.settings.inbox_ids = this.inboxIds;
      }

      if (this.isHookTypeInbox && this.values.inbox) {
        hookPayload.inbox_id = this.values.inbox;
      }

      return hookPayload;
    },
    async submitForm() {
      if (this.isIntegrationCaptain && !this.inboxIds.length) {
        this.alertMessage = this.$t(
          'INTEGRATION_SETTINGS.CAPTAIN.ERRORS.CREATE_INBOX_IDS'
        );
        useAlert(this.alertMessage);
        return;
      }

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
        useAlert(this.alertMessage);
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto integration-hooks">
    <woot-modal-header
      :header-title="integration.name"
      :header-content="integration.description"
    />
    <formulate-form
      v-slot="{ hasErrors }"
      v-model="values"
      class="w-full"
      @submit="submitForm"
    >
      <formulate-input
        v-for="item in formItems"
        :key="item.name"
        v-bind="item"
      />
      <formulate-input
        v-if="isIntegrationDialogflow"
        :options="inboxes"
        type="select"
        name="inbox"
        :placeholder="$t('INTEGRATION_APPS.ADD.FORM.INBOX.LABEL')"
        :label="$t('INTEGRATION_APPS.ADD.FORM.INBOX.PLACEHOLDER')"
        validation="required"
        validation-name="Inbox"
      />
      <WithLabel
        name="inbox"
        :label="$t('INTEGRATION_APPS.ADD.FORM.INBOX.PLACEHOLDER')"
      >
        <InboxFilter
          v-if="isIntegrationCaptain"
          class="w-full"
          multiple
          @inboxFilterSelection="setInboxes"
        />
      </WithLabel>
      <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
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
