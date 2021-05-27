<template>
  <div class="row content-box full-height">
    <woot-button
      v-if="showAddButton"
      color-scheme="success"
      class-names="button--fixed-right-top"
      icon="ion-android-add-circle"
      @click="openAddPopup()"
    >
      {{ `Add new ${integration.id}` }}
    </woot-button>
    <div v-if="isIntegrationLoaded">
      <div v-if="isIntegrationMultiple">
        <multiple-integration-hooks
          :integration="integration"
          :open-delete-popup="openDeletePopup"
        />
      </div>

      <div v-if="isIntegrationSingle">
        <single-integration-hooks :integration="integration" />
      </div>
    </div>

    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <new-hook :on-close="hideAddPopup" :integration="integration" />
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
import NewHook from './NewHook';
import SingleIntegrationHooks from './SingleIntegrationHooks';
import MultipleIntegrationHooks from './MultipleIntegrationHooks';

export default {
  components: {
    NewHook,
    SingleIntegrationHooks,
    MultipleIntegrationHooks,
  },
  data() {
    return {
      loading: {},
      showAddPopup: false,
      showDeleteConfirmationPopup: false,
      selectedHook: {},
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
    isIntegrationLoaded() {
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
      if (
        this.uiFlags.isFetching ||
        isEmptyObject(this.integration) ||
        this.isIntegrationSingle ||
        (this.integration &&
          !this.integration.allow_multiple_hooks &&
          this.integration.hooks.length >= 1)
      ) {
        return false;
      }
      return true;
    },
  },
  methods: {
    showAlert(message) {
      bus.$emit('newToastMessage', message);
    },
    openAddPopup() {
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
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
        this.showAlert('Hooke deleted succssfully');
        this.closeDeletePopup();
      } catch (error) {
        this.showAlert('Something went wrong');
      }
    },
  },
};
</script>
<style scoped lang="scss">
.webhook-link {
  word-break: break-word;
}
.integration-hooks {
  width: 100%;
}
</style>
