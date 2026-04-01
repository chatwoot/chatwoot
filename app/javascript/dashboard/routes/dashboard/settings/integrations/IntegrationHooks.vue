<script>
import { isEmptyObject } from '../../../../helper/commons';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useIntegrationHook } from 'dashboard/composables/useIntegrationHook';
import NewHook from './NewHook.vue';
import SingleIntegrationHooks from './SingleIntegrationHooks.vue';
import MultipleIntegrationHooks from './MultipleIntegrationHooks.vue';
import ConfirmDialog from 'dashboard/components-next/dialog/Dialog.vue';

export default {
  components: {
    ConfirmDialog,
    NewHook,
    SingleIntegrationHooks,
    MultipleIntegrationHooks,
  },
  props: {
    integrationId: {
      type: [String, Number],
      required: true,
    },
  },
  setup(props) {
    const { integrationId } = props;

    const {
      integration,
      isIntegrationMultiple,
      isIntegrationSingle,
      isHookTypeInbox,
    } = useIntegrationHook(integrationId);
    return {
      integration,
      isIntegrationMultiple,
      isIntegrationSingle,
      isHookTypeInbox,
    };
  },
  data() {
    return {
      loading: {},
      showAddHookModal: false,
      selectedHook: {},
      alertMessage: '',
    };
  },
  computed: {
    ...mapGetters({ uiFlags: 'integrations/getUIFlags' }),
    showIntegrationHooks() {
      return !this.uiFlags.isFetching && !isEmptyObject(this.integration);
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
      this.selectedHook = response;
      this.$nextTick(() => {
        this.$refs.hookDeleteDialog?.open();
      });
    },
    async confirmDeletion() {
      this.$refs.hookDeleteDialog?.close();
      try {
        await this.$store.dispatch('integrations/deleteHook', {
          hookId: this.selectedHook.id,
          appId: this.selectedHook.app_id,
        });
        this.alertMessage = this.$t(
          'INTEGRATION_APPS.DELETE.API.SUCCESS_MESSAGE'
        );
      } catch (error) {
        const errorMessage = error?.response?.data?.message;
        this.alertMessage =
          errorMessage || this.$t('INTEGRATION_APPS.DELETE.API.ERROR_MESSAGE');
      } finally {
        useAlert(this.alertMessage);
      }
    },
  },
};
</script>

<template>
  <div class="overflow-auto p-4 w-full my-auto flex flex-wrap h-full">
    <div v-if="showIntegrationHooks" class="w-full">
      <div v-if="isIntegrationMultiple">
        <MultipleIntegrationHooks
          :integration-id="integrationId"
          :show-add-button="showAddButton"
          @add="openAddHookModal"
          @delete="openDeletePopup"
        />
      </div>

      <div v-if="isIntegrationSingle">
        <SingleIntegrationHooks
          :integration-id="integrationId"
          @add="openAddHookModal"
          @delete="openDeletePopup"
        />
      </div>
    </div>

    <woot-modal v-model:show="showAddHookModal" :on-close="hideAddHookModal">
      <NewHook :integration-id="integrationId" @close="hideAddHookModal" />
    </woot-modal>

    <ConfirmDialog
      ref="hookDeleteDialog"
      type="alert"
      :title="deleteTitle"
      :description="deleteMessage"
      :confirm-button-label="confirmText"
      :cancel-button-label="cancelText"
      @confirm="confirmDeletion"
    />
  </div>
</template>
