<script>
import { isEmptyObject } from '../../../../helper/commons';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useIntegrationHook } from 'dashboard/composables/useIntegrationHook';
import NewHook from './NewHook.vue';
import SingleIntegrationHooks from './SingleIntegrationHooks.vue';
import MultipleIntegrationHooks from './MultipleIntegrationHooks.vue';

export default {
  components: {
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
      showDeleteConfirmationPopup: false,
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
        useAlert(this.alertMessage);
      }
    },
  },
};
</script>

<template>
  <div class="overflow-auto p-4 max-w-full my-auto flex flex-wrap h-full">
    <woot-button
      v-if="showAddButton"
      color-scheme="success"
      class-names="button--fixed-top"
      icon="add-circle"
      @click="openAddHookModal"
    >
      {{ $t('INTEGRATION_APPS.ADD_BUTTON') }}
    </woot-button>
    <div v-if="showIntegrationHooks" class="w-full">
      <div v-if="isIntegrationMultiple">
        <MultipleIntegrationHooks
          :integration-id="integrationId"
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

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="deleteTitle"
      :message="deleteMessage"
      :confirm-text="confirmText"
      :reject-text="cancelText"
    />
  </div>
</template>
