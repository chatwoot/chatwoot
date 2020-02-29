<template>
  <div class="row content-box full-height">
    <button
      class="button nice icon success button--fixed-right-top"
      @click="openAddPopup()"
    >
      <i class="icon ion-android-add-circle"></i>
      {{ $t('INTEGRATION_SETTINGS.WEBHOOK.HEADER_BTN_TXT') }}
    </button>
    <!-- List Canned Response -->
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
            <!-- Header -->
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
              <!-- Short Code  -->
              <td>{{ webHookItem.url }}</td>
              <!-- Action Buttons -->
              <td class="button-wrapper">
                <div @click="openDeletePopup(webHookItem, index)">
                  <woot-submit-button
                    :button-text="
                      $t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.BUTTON_TEXT')
                    "
                    :loading="loading[webHookItem.id]"
                    icon-class="ion-close-circled"
                    button-class="link hollow grey-btn"
                  />
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="small-4 columns">
        <span v-html="$t('INTEGRATION_SETTINGS.WEBHOOK.SIDEBAR_TXT')"></span>
      </div>
    </div>

    <!-- Add Agent -->
    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <new-webhook :on-close="hideAddPopup" />
    </woot-modal>

    <!-- Delete Canned Response -->
    <delete-webhook
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
/* eslint no-console: 0 */
/* eslint-env browser */

import { mapGetters } from 'vuex';
import NewWebhook from './New';
import DeleteWebhook from './Delete';

export default {
  components: {
    NewWebhook,
    DeleteWebhook,
  },
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
      records: 'getWebHooks',
      uiFlags: 'getUIFlags',
    }),
  },
  mounted() {
    // Fetch API Call
    this.$store.dispatch('getAllWebHooks');
  },
  methods: {
    // Edit Function
    openAddPopup() {
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
    },

    // Delete Modal Functions
    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedWebHook = response;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    // Set loading and call Delete API
    confirmDeletion() {
      this.loading[this.selectedWebHook.id] = true;
      this.closeDeletePopup();
      this.deleteCannedResponse(this.selectedWebHook.id);
    },
    deleteCannedResponse(id) {
      this.$store
        .dispatch('deleteWebHook', id)
        .then(() => {
          this.showAlert(
            this.$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.API.SUCCESS_MESSAGE')
          );
        })
        .catch(() => {
          this.showAlert(
            this.$t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.API.ERROR_MESSAGE')
          );
        });
    },
  },
};
</script>
