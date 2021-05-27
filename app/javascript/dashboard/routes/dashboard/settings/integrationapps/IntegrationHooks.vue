<template>
  <div class="row content-box full-height">
    <woot-button
      v-if="showAddButton"
      color-scheme="success"
      class-names="button--fixed-right-top"
      icon="ion-android-add-circle"
      @click="openAddHookModal()"
    >
      {{ `Add new ${integration.id}` }}
    </woot-button>
    <div v-if="showIntegrationHooks" class="integration-hooks">
      <div v-if="isIntegrationMultiple">
        <multiple-integration-hooks
          :integration="integration"
          :delete-hook="openDeletePopup"
        />
      </div>

      <div v-if="isIntegrationSingle">
        <single-integration-hooks
          :integration="integration"
          :delete-hook="openDeletePopup"
          :add-hook="openAddHookModal"
        />
      </div>
    </div>

    <woot-modal :show.sync="showAddHookModal" :on-close="hideAddHookModal">
      <new-hook :on-close="hideAddHookModal" :integration="integration" />
    </woot-modal>

    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.TITLE')"
      :message="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.MESSAGE')"
      :confirm-text="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.YES')"
      :reject-text="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.NO')"
    />
  </div>
</template>
<script>
import { isEmptyObject } from '../../../../helper/commons';
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import NewHook from './NewHook';
import SingleIntegrationHooks from './SingleIntegrationHooks';
import MultipleIntegrationHooks from './MultipleIntegrationHooks';

export default {
  components: {
    NewHook,
    SingleIntegrationHooks,
    MultipleIntegrationHooks,
  },
  mixins: [alertMixin],
  data() {
    return {
      loading: {},
      showAddHookModal: false,
      showDeleteConfirmationPopup: false,
      selectedHook: {},
      deleteHook: {
        showAlert: false,
        showLoading: false,
        message: '',
      },
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'integrations/getUIFlags',
    }),
    integration() {
      return this.$store.getters['integrations/getIntegration'](
        this.$route.params.integration_id
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
    inboxName(hook) {
      if (hook.inbox) {
        return hook.inbox.name;
      }
      return '';
    },
    async confirmDeletion() {
      try {
        await this.$store.dispatch(
          'integrations/deleteHook',
          this.selectedHook.id
        );
        this.deleteHook.message = 'Hooke deleted succssfully';
        this.closeDeletePopup();
      } catch (error) {
        const errorMessage = error?.response?.data?.message;
        this.deleteHook.message = errorMessage || 'Something went wrong';
      } finally {
        this.deleteHook.showLoading = false;
        this.showAlert(this.deleteHook.message);
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
