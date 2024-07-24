<template>
  <div
    class="flex flex-col md:flex-row justify-between items-start md:items-center"
  >
    <div class="flex items-center justify-start m-0 mx-4 flex-1">
      <img
        :src="`/dashboard/images/integrations/${integrationId}.png`"
        class="p-2 h-16 w-16 mr-4"
      />
      <div>
        <h3 class="text-xl font-medium mb-1 text-slate-800 dark:text-slate-100">
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
      <router-link
        :to="
          frontendURL(
            `accounts/${accountId}/settings/integrations/` + integrationId
          )
        "
      >
        <div v-if="integrationEnabled">
          <div v-if="integrationAction === 'disconnect'">
            <div @click="openDeletePopup">
              <woot-submit-button
                :button-text="
                  actionButtonText ||
                  $t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.BUTTON_TEXT')
                "
                button-class="smooth alert"
              />
            </div>
          </div>
          <div v-else>
            <button class="button nice">
              {{ $t('INTEGRATION_SETTINGS.WEBHOOK.CONFIGURE') }}
            </button>
          </div>
        </div>
      </router-link>
      <div v-if="!integrationEnabled">
        <a :href="integrationAction" class="button success nice rounded">
          {{ $t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT') }}
        </a>
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
<script>
import { mapGetters } from 'vuex';
import { frontendURL } from '../../../../helper/URLHelper';
import { useAlert } from 'dashboard/composables';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  mixins: [globalConfigMixin],
  props: {
    integrationId: {
      type: [String, Number],
      required: true,
    },
    integrationLogo: { type: String, default: '' },
    integrationName: { type: String, default: '' },
    integrationDescription: { type: String, default: '' },
    integrationEnabled: { type: Boolean, default: false },
    integrationAction: { type: String, default: '' },
    actionButtonText: { type: String, default: '' },
    deleteConfirmationText: { type: Object, default: () => ({}) },
  },
  data() {
    return {
      showDeleteConfirmationPopup: false,
    };
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      accountId: 'getCurrentAccountId',
      globalConfig: 'globalConfig/get',
    }),
  },
  methods: {
    frontendURL,
    openDeletePopup() {
      this.showDeleteConfirmationPopup = true;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    confirmDeletion() {
      this.closeDeletePopup();
      this.deleteIntegration(this.deleteIntegration);
      this.$router.push({ name: 'settings_integrations' });
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
  },
};
</script>
