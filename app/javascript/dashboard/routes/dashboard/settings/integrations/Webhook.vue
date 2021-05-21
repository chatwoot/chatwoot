<template>
  <div class="row content-box full-height">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-right-top"
      icon="ion-android-add-circle"
      @click="openAddPopup()"
    >
      {{ $t('INTEGRATION_SETTINGS.WEBHOOK.HEADER_BTN_TXT') }}
    </woot-button>

    <div class="row">
      <div class="small-8 columns">
        <p
          v-if="!uiFlags.fetchingList && !records.length"
          class="no-items-error-message"
        >
          {{ $t('INTEGRATION_SETTINGS.WEBHOOK.LIST.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.fetchingList"
          :message="$t('INTEGRATION_SETTINGS.WEBHOOK.LOADING')"
        />

        <table
          v-if="!uiFlags.fetchingList && records.length"
          class="woot-table"
        >
          <thead>
            <th
              v-for="thHeader in $t(
                'INTEGRATION_SETTINGS.WEBHOOK.LIST.TABLE_HEADER'
              )"
              :key="thHeader"
            >
              {{ thHeader }}
            </th>
          </thead>
          <tbody>
            <tr v-for="(webHookItem, index) in records" :key="webHookItem.id">
              <td class="webhook-link">
                {{ webHookItem.url }}
              </td>
              <td class="button-wrapper">
                <div @click="openDeletePopup(webHookItem, index)">
                  <woot-button
                    :is-loading="loading[webHookItem.id]"
                    icon="ion-close-circled"
                    variant="link"
                    color-scheme="secondary"
                  >
                    {{ $t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.BUTTON_TEXT') }}
                  </woot-button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="small-4 columns">
        <span
          v-html="
            useInstallationName(
              $t('INTEGRATION_SETTINGS.WEBHOOK.SIDEBAR_TXT'),
              globalConfig.installationName
            )
          "
        />
      </div>
    </div>

    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <new-webhook :on-close="hideAddPopup" />
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
import { mapGetters } from 'vuex';
import NewWebhook from './New';
import alertMixin from 'shared/mixins/alertMixin';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  components: {
    NewWebhook,
  },
  mixins: [alertMixin, globalConfigMixin],
  data() {
    return {
      loading: {},
      showAddPopup: false,
      showDeleteConfirmationPopup: false,
      selectedWebHook: {},
    };
  },
  computed: {
    ...mapGetters({
      records: 'webhooks/getWebhooks',
      uiFlags: 'webhooks/getUIFlags',
      globalConfig: 'globalConfig/get',
    }),
  },
  mounted() {
    this.$store.dispatch('webhooks/get');
  },
  methods: {
    openAddPopup() {
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
    },
    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedWebHook = response;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    confirmDeletion() {
      this.loading[this.selectedWebHook.id] = true;
      this.closeDeletePopup();
      this.deleteWebhook(this.selectedWebHook.id);
    },
    async deleteWebhook(id) {
      try {
        await this.$store.dispatch('webhooks/delete', id);
        this.showAlert(
          this.$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.API.SUCCESS_MESSAGE')
        );
      } catch (error) {
        this.showAlert(
          this.$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.API.ERROR_MESSAGE')
        );
      }
    },
  },
};
</script>
<style scoped lang="scss">
.webhook-link {
  word-break: break-word;
}
</style>
