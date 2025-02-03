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
      showCalIntegrationPopup: false,
      loading: false,
      cal_user_slug: '',
      requestRaised: false,
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
    openCalIntegrationPopup() {
      this.showCalIntegrationPopup = true;
    },
    closeCalIntegrationPopup() {
      this.showCalIntegrationPopup = false;
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

    async addCalIntegration() {
      try {
        this.loading = true;
        if (this.cal_user_slug.trim() === '') {
          useAlert('Field cannot be empty');
          return;
        }
        const regex =
          /(https?:\/\/(cal\.id|calid\.in|localhost):?[\d]*\/)([^/]+)$/;
        const match = this.cal_user_slug.match(regex);
        if (match) {
          this.cal_user_slug = match[3];
        }

        this.closeCalIntegrationPopup();
        const res = await this.$store.dispatch(
          'integrations/addOneHashIntegration',
          {
            integrationId: this.integrationId,
            slug: this.cal_user_slug,
          }
        );
        this.requestRaised = true;
        useAlert(res.data.message);
      } catch (error) {
        useAlert(this.$t('INTEGRATION_SETTINGS.ADD.API.ERROR_MESSAGE'));
      } finally {
        this.loading = false;
      }
    },

    async handleConfigure() {
      if (this.integrationId === 'onehash_cal') {
        this.openCalIntegrationPopup();
      } else {
        useAlert('App not configured');
      }
    },
  },
};
</script>

<template>
  <div>
    <div
      class="flex flex-col items-start bg-white justify-between md:flex-row md:items-center shadow-lg border-1 rounded-md py-2"
    >
      <div class="flex items-center justify-start flex-1 m-0 mx-4">
        <img
          :src="`/dashboard/images/integrations/${integrationId}.png`"
          class="w-16 h-16 p-2 mr-4"
        />
        <div>
          <h3
            class="mb-1 text-xl font-medium text-slate-800 dark:text-slate-100"
          >
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
          <woot-button
            variant="smooth"
            color-scheme="danger"
            icon="delete"
            @click="openDeletePopup"
          >
            {{
              deleteButtonText ||
              $t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.BUTTON_TEXT')
            }}
          </woot-button>
          <!-- <button class="button alert" @click="openDeletePopup">
          {{
            deleteButtonText ||
            $t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.BUTTON_TEXT')
          }}
        </button> -->
        </div>
        <div v-else>
          <woot-button
            variant="smooth"
            color-scheme="secondary"
            icon="plus-sign"
            :is-loading="loading"
            @click="handleConfigure"
          >
            {{ $t('INTEGRATION_SETTINGS.WEBHOOK.CONFIGURE') }}
          </woot-button>
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

      <woot-modal
        :show.sync="showCalIntegrationPopup"
        :on-close="closeCalIntegrationPopup"
      >
        <div class="bg-white p-6 rounded-lg text-center">
          <!-- Modal Title -->
          <h2 class="text-xl font-semibold mb-4">
            {{ $t('INTEGRATION_SETTINGS.ONEHASH_CAL.ADD_TITLE') }}
          </h2>

          <p class="text-gray-700 mb-4">
            {{ $t('INTEGRATION_SETTINGS.ONEHASH_CAL.ADD_MESSAGE') }}
          </p>

          <input
            v-model="cal_user_slug"
            class="w-full p-2 mb-4 border border-gray-300 rounded-md"
            type="text"
            @keydown.enter="addCalIntegration"
          />

          <button class="button nice" @click="addCalIntegration">
            {{ $t('INTEGRATION_SETTINGS.ONEHASH_CAL.PROCEED') }}
          </button>
        </div>
      </woot-modal>
    </div>
    <p v-if="requestRaised" class="mx-3 mt-2 text-sm text-gray-500">
      {{
        'Note : After accepting request from Cal, please refresh this page to view changes'
      }}
    </p>
  </div>
</template>
