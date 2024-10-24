<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  mixins: [globalConfigMixin],
  props: {
    integrationId: {
      type: [String, Number],
      required: true,
    },
    integrationName: { type: String, default: '' },
    integrationDescription: { type: String, default: '' },
    integrationEnabled: { type: Boolean, default: false },
    deleteButtonText: { type: String, default: '' },
    deleteConfirmationText: { type: Object, default: () => ({}) },
  },
  data() {
    return {
      showDeleteConfirmationPopup: false,
    };
  },
  computed: {
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
  },
  methods: {
    openDeletePopup() {
      this.showDeleteConfirmationPopup = true;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    confirmDeletion() {
      this.closeDeletePopup();
      this.deleteIntegration(this.deleteIntegration);
      window.location.reload();
    },
    async deleteIntegration() {
      try {
        await this.$store.dispatch(
          'integrations/deleteIntegration',
          this.integrationId
        );
        useAlert(this.$t('INTEGRATION_SETTINGS.DELETE.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(
          this.$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.API.ERROR_MESSAGE')
        );
      }
    },

    async addIntegration() {
      try {
        await this.$store.dispatch(
          'integrations/addOneHashIntegration',
          this.integrationId
        );
        window.location.reload();
        useAlert(this.$t('INTEGRATION_SETTINGS.ADD.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INTEGRATION_SETTINGS.ADD.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>

<template>
  <div
    class="flex flex-col items-start justify-between md:flex-row md:items-center shadow-md rounded-md py-2"
  >
    <div class="flex items-center justify-start flex-1 m-0 mx-4">
      <img
        :src="`/dashboard/images/integrations/${integrationId}.png`"
        class="w-16 h-16 p-2 mr-4"
      />
      <div>
        <h3 class="mb-1 text-xl font-medium text-slate-800 dark:text-slate-100">
          {{ integrationName }}
        </h3>
        <p class="text-slate-700 dark:text-slate-200">
          {{
            useInstallationName(
              integrationDescription,
              globalConfig.installationName
            )
          }}
        </p>
      </div>
    </div>
    <div class="flex justify-center items-center mb-0 w-[15%]">
      <div v-if="integrationEnabled">
        <button class="button alert" @click="openDeletePopup">
          {{
            deleteButtonText ||
            $t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.BUTTON_TEXT')
          }}
        </button>
      </div>
      <div v-else>
        <button class="button nice" @click="addIntegration">
          {{ $t('INTEGRATION_SETTINGS.WEBHOOK.CONFIGURE') }}
        </button>
      </div>
    </div>
    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="
        deleteConfirmationText.title ||
        $t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.TITLE')
      "
      :message="
        deleteConfirmationText.message ||
        $t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.MESSAGE')
      "
      :confirm-text="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.YES')"
      :reject-text="$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.CONFIRM.NO')"
    />
  </div>
</template>
