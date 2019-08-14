<template>
  <div class="column content-box">
    <!-- List Canned Response -->
    <div class="row">
      <div class="small-8 columns">
        <p v-if="!inboxesList.length" class="no-items-error-message">
          {{ $t('INBOX_MGMT.LIST.404') }}
          <router-link to="/u/settings/inboxes/new" v-if="isAdmin()">
            {{ $t('SETTINGS.INBOXES.NEW_INBOX') }}
          </router-link>
        </p>

        <table class="woot-table" v-if="inboxesList.length">
          <tbody>
            <tr v-for="item in inboxesList">
              <td><img class="woot-thumbnail" :src="item.avatarUrl" alt="No Page Image"/></td>
              <!-- Short Code  -->
              <td>
                <span class="agent-name">{{ item.label }}</span>
                <span>Facebook</span>
              </td>

              <!-- Action Buttons -->
              <td>
                <div class="button-wrapper">
                  <div @click="openSettings(item)" v-if="isAdmin()">
                    <woot-submit-button
                    :button-text="$t('INBOX_MGMT.SETTINGS')"
                    icon-class="ion-gear-b"
                    button-class="link hollow grey-btn"
                    />
                  </div>
                  <!-- <div>
                    <woot-submit-button
                    :button-text="$t('INBOX_MGMT.REAUTH')"
                    icon-class="ion-edit"
                    button-class="link hollow grey-btn"
                    />
                  </div> -->
                  <div @click="openDelete(item)" v-if="isAdmin()">
                    <woot-submit-button
                      :button-text="$t('INBOX_MGMT.DELETE.BUTTON_TEXT')"
                      :loading="loading[item.id]"
                      icon-class="ion-close-circled"
                      button-class="link hollow grey-btn"
                    />
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="small-4 columns">
        <span v-html="$t('INBOX_MGMT.SIDEBAR_TXT')"></span>
      </div>
    </div>
    <settings
      :show.sync="showSettings"
      :on-close="closeSettings"
      :inbox="selectedInbox"
      v-if="showSettings"
    />

    <delete-inbox
      :show.sync="showDeletePopup"
      :on-close="closeDelete"
      :on-confirm="confirmDeletion"
      :title="$t('INBOX_MGMT.DELETE.CONFIRM.TITLE')"
      :message="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />
  </div>
</template>
<script>
/* global bus */

import { mapGetters } from 'vuex';
import InboxListItem from '../../../../components/widgets/InboxListItem';
import Settings from './Settings';
import DeleteInbox from './DeleteInbox';
import adminMixin from '../../../../mixins/isAdmin';

export default {
  components: {
    InboxListItem,
    Settings,
    DeleteInbox,
  },
  mixins: [adminMixin],
  data() {
    return {
      loading: {},
      showSettings: false,
      showDeletePopup: false,
      selectedInbox: {},
    };
  },
  computed: {
    ...mapGetters({
      inboxesList: 'getInboxesList',
    }),
    // Delete Modal
    deleteConfirmText() {
      return `${this.$t('INBOX_MGMT.DELETE.CONFIRM.YES')} ${this.selectedInbox.label}`;
    },
    deleteRejectText() {
      return `${this.$t('INBOX_MGMT.DELETE.CONFIRM.NO')} ${this.selectedInbox.label}`;
    },
    deleteMessage() {
      return `${this.$t('INBOX_MGMT.DELETE.CONFIRM.MESSAGE')} ${this.selectedInbox.label} ?`;
    },
  },
  methods: {
    openSettings(inbox) {
      this.showSettings = true;
      this.selectedInbox = inbox;
    },
    closeSettings() {
      this.showSettings = false;
      this.selectedInbox = {};
    },
    deleteInbox({ channel_id }) {
      this.$store.dispatch('deleteInbox', channel_id)
        .then(() => bus.$emit('newToastMessage', this.$t('INBOX_MGMT.DELETE.API.SUCCESS_MESSAGE')))
        .catch(() => bus.$emit('newToastMessage', this.$t('INBOX_MGMT.DELETE.API.ERROR_MESSAGE')));
    },

    confirmDeletion() {
      this.deleteInbox(this.selectedInbox);
      this.closeDelete();
    },
    openDelete(inbox) {
      this.showDeletePopup = true;
      this.selectedInbox = inbox;
    },
    closeDelete() {
      this.showDeletePopup = false;
      this.selectedInbox = {};
    },
  },
};
</script>
