<template>
  <div class="row content-box full-height">
    <woot-button
      v-if="showAddButton"
      color-scheme="success"
      class-names="button--fixed-right-top"
      icon="add-circle"
      @click="openAddHookModal"
    >
      {{ $t('INTEGRATION_APPS.ADD_BUTTON') }}
    </woot-button>
    <div v-if="showIntegrationHooks" class="integration-hooks">
      <div v-if="isIntegrationMultiple">
        <multiple-integration-hooks
          :integration="integration"
          @delete="openDeletePopup"
        />
      </div>

      <div v-if="isIntegrationSingle">
        <single-integration-hooks
          :integration="integration"
          @add="openAddHookModal"
          @delete="openDeletePopup"
        />
      </div>
    </div>

    <woot-modal :show.sync="showAddHookModal" :on-close="hideAddHookModal">
      <new-hook :integration="integration" @close="hideAddHookModal" />
    </woot-modal>

    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="deleteTitle"
      :message="deleteMessage"
      :confirm-text="confirmText"
      :reject-text="cancelText"
    />
  </div>
</template>
<script>
import { isEmptyObject } from '../../../../helper/commons';
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import hookMixin from './hookMixin';
import NewHook from './NewHook';
import SingleIntegrationHooks from './SingleIntegrationHooks';
import MultipleIntegrationHooks from './MultipleIntegrationHooks';

export default {
  components: {
    NewHook,
    SingleIntegrationHooks,
    MultipleIntegrationHooks,
  },
  mixins: [alertMixin, hookMixin],
  props: {
    integrationId: {
      type: [String, Number],
      required: true,
    },
  },
  data() {
    return {
      loading: {},
      showAddHookModal: false,
      showDeleteConfirmationPopup: false,
      selectedHook: {},
      alertMessage: '',
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'integrations/getUIFlags' }),
    integration() {
      return this.$store.getters['integrations/getIntegration'](
        this.integrationId
      );
    },
    showIntegrationHooks() {
      return !this.uiFlags.isFetching && !isEmptyObject(this.integration);
    },
    integrationType() {
      return this.integration.allow_multiple_hooks ? 'multiple' : 'single';
    },
    isIntegrationMultiple() {
      return this.integrationType === 'multiple';
    },
    isIntegrationSingle() {
      return this.integrationType === 'single';
    },
    showAddButton() {
      return this.showIntegrationHooks && this.isIntegrationMultiple;
    },
    deleteTitle() {
      return this.isHookTypeInbox
        ? this.$t('INTEGRATION_APPS.DELETE.TITLE.INBOX')
        : this.$t('INTEGRATION_APPS.DELETE.TITLE.ACCOUNT');
    },
    deleteMessage() {
      return this.isHookTypeInbox
        ? this.$t('INTEGRATION_APPS.DELETE.MESSAGE.INBOX')
        : this.$t('INTEGRATION_APPS.DELETE.MESSAGE.ACCOUNT');
    },
    confirmText() {
      return this.isHookTypeInbox
        ? this.$t('INTEGRATION_APPS.DELETE.CONFIRM_BUTTON_TEXT.INBOX')
        : this.$t('INTEGRATION_APPS.DELETE.CONFIRM_BUTTON_TEXT.ACCOUNT');
    },
    cancelText() {
      return this.$t('INTEGRATION_APPS.DELETE.CANCEL_BUTTON_TEXT');
    },
  },
  methods: {
    openAddHookModal() {
      this.showAddHookModal = true;
    },
    hideAddHookModal() {
      this.showAddHookModal = false;
    },
    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedHook = response;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    async confirmDeletion() {
      try {
        await this.$store.dispatch('integrations/deleteHook', {
          hookId: this.selectedHook.id,
          appId: this.selectedHook.app_id,
        });
        this.alertMessage = this.$t(
          'INTEGRATION_APPS.DELETE.API.SUCCESS_MESSAGE'
        );
        this.closeDeletePopup();
      } catch (error) {
        const errorMessage = error?.response?.data?.message;
        this.alertMessage =
          errorMessage || this.$t('INTEGRATION_APPS.DELETE.API.ERROR_MESSAGE');
      } finally {
        this.showAlert(this.alertMessage);
      }
    },
  },
};
</script>
<style scoped lang="scss">
.integration-hooks {
  width: 100%;
}
</style>
