<template>
  <div class="row content-box full-height">
    <woot-button
        color-scheme="success"
        class-names="button--fixed-right-top"
        icon="add-circle"
        @click="openAddPopup()"
    >
      {{ $t('INTEGRATION_SETTINGS.SHOPIFY.HEADER_BTN_TXT') }}
    </woot-button>

    <div class="row">
      <div class="small-8 columns with-right-space ">
        <p
            v-if="!uiFlags.fetchingList && !records.length"
            class="no-items-error-message"
        >
          {{ $t('INTEGRATION_SETTINGS.SHOPIFY.LIST.404') }}
        </p>
        <woot-loading-state
            v-if="uiFlags.fetchingList"
            :message="$t('INTEGRATION_SETTINGS.SHOPIFY.LOADING')"
        />

        <table
            v-if="!uiFlags.fetchingList && records.length"
            class="woot-table"
        >
          <thead>
          <th
              v-for="thHeader in $t(
                'INTEGRATION_SETTINGS.SHOPIFY.LIST.TABLE_HEADER'
              )"
              :key="thHeader"
          >
            {{ thHeader }}
          </th>
          </thead>
          <tbody>
          <tr v-for="(shopifyItem, index) in records" :key="shopifyItem.id">
            <td class="webhook-link">
              {{ shopifyItem.account_name }}
            </td>
            <td class="button-wrapper">
              <woot-button
                  v-tooltip.top="
                    $t('INTEGRATION_SETTINGS.SHOPIFY.EDIT.BUTTON_TEXT')
                  "
                  variant="smooth"
                  size="tiny"
                  color-scheme="secondary"
                  icon="edit"
                  @click="openEditPopup(shopifyItem)"
              >
              </woot-button>
              <woot-button
                  v-tooltip.top="
                    $t('INTEGRATION_SETTINGS.SHOPIFY.DELETE.BUTTON_TEXT')
                  "
                  variant="smooth"
                  color-scheme="alert"
                  size="tiny"
                  icon="dismiss-circle"
                  @click="openDeletePopup(shopifyItem, index)"
              >
              </woot-button>
            </td>
          </tr>
          </tbody>
        </table>
      </div>

      <div class="small-4 columns">
        <span
            v-html="
            useInstallationName(
              $t('INTEGRATION_SETTINGS.SHOPIFY.SIDEBAR_TXT'),
              globalConfig.installationName
            )
          "
        />
      </div>
    </div>

    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <new-shopify :on-close="hideAddPopup"/>
    </woot-modal>

    <woot-modal :show.sync="showEditPopup" :on-close="hideEditPopup">
      <update-shopify
          v-if="showEditPopup"
          :account-name="selectedAccount.account_name"
          :api-key="selectedAccount.api_key"
          :api-secret="selectedAccount.api_secret"
          :id="selectedAccount.id"
          :redirect-url="selectedAccount.redirect_url"
          :access-token="selectedAccount.access_token"
          :updated-at="selectedAccount.updated_at"
          :on-close="hideEditPopup"
      />
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
import {mapGetters} from 'vuex';
import NewShopify from './NewShopify';
import UpdateShopify from './UpdateShopify';
import alertMixin from 'shared/mixins/alertMixin';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  components: {
    UpdateShopify,
    NewShopify,
  },
  mixins: [alertMixin, globalConfigMixin],
  data() {
    return {
      loading: {},
      showAddPopup: false,
      showEditPopup: false,
      showDeleteConfirmationPopup: false,
      selectedAccount: {},
    };
  },
  computed: {
    ...mapGetters({
      records: 'shopify/getShopifyAccounts',
      uiFlags: 'shopify/getUIFlags',
      globalConfig: 'globalConfig/get',
    }),
  },
  mounted() {
    this.$store.dispatch('shopify/get');
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
      this.selectedAccount = response;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    openEditPopup(shopify) {
      this.showEditPopup = true;
      this.selectedAccount = shopify;
    },
    hideEditPopup() {
      this.showEditPopup = false;
    },
    confirmDeletion() {
      this.loading[this.selectedAccount.id] = true;
      this.closeDeletePopup();
      this.removeShopify(this.selectedAccount.id);
    },
    async removeShopify(id) {
      try {
        await this.$store.dispatch('shopify/remove', id);
        await this.$store.dispatch('shopify/get');
        this.showAlert(
            this.$t('INTEGRATION_SETTINGS.SHOPIFY.DELETE.API.SUCCESS_MESSAGE')
        );
      } catch (error) {
        this.showAlert(
            this.$t('INTEGRATION_SETTINGS.SHOPIFY.DELETE.API.ERROR_MESSAGE')
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

.button-wrapper button:nth-child(2) {
  margin-left: var(--space-normal);
}
</style>
