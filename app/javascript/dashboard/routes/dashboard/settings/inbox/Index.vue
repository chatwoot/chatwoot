<template>
  <div class="column content-box">
    <!-- List Canned Response -->
    <div class="row">
      <div class="small-8 columns">
        <p v-if="!inboxesList.length" class="no-items-error-message">
          {{ $t('INBOX_MGMT.LIST.404') }}
          <router-link
            v-if="isAdmin"
            :to="addAccountScoping('settings/inboxes/new')"
          >
            {{ $t('SETTINGS.INBOXES.NEW_INBOX') }}
          </router-link>
        </p>

        <table v-if="inboxesList.length" class="woot-table">
          <tbody>
            <tr v-for="item in inboxesList" :key="item.id">
              <td>
                <img
                  v-if="item.avatar_url"
                  class="woot-thumbnail"
                  :src="item.avatar_url"
                  alt="No Page Image"
                />
                <img
                  v-else
                  class="woot-thumbnail"
                  src="~dashboard/assets/images/flag.svg"
                  alt="No Page Image"
                />
              </td>
              <!-- Short Code  -->
              <td>
                <span class="agent-name">{{ item.name }}</span>
                <span v-if="item.channel_type === 'Channel::FacebookPage'">
                  Facebook
                </span>
                <span v-if="item.channel_type === 'Channel::WebWidget'">
                  Website
                </span>
                <span v-if="item.channel_type === 'Channel::TwitterProfile'">
                  Twitter
                </span>
                <span v-if="item.channel_type === 'Channel::TwilioSms'">
                  Twilio SMS
                </span>
                <span v-if="item.channel_type === 'Channel::Email'">
                  Email
                </span>
                <span v-if="item.channel_type === 'Channel::Api'">
                  Api
                </span>
              </td>

              <!-- Action Buttons -->
              <td>
                <div class="button-wrapper">
                  <router-link
                    :to="addAccountScoping(`settings/inboxes/${item.id}`)"
                  >
                    <woot-submit-button
                      v-if="isAdmin"
                      :button-text="$t('INBOX_MGMT.SETTINGS')"
                      icon-class="ion-gear-b"
                      button-class="link hollow grey-btn"
                    />
                  </router-link>

                  <woot-submit-button
                    v-if="isAdmin"
                    :button-text="$t('INBOX_MGMT.DELETE.BUTTON_TEXT')"
                    :loading="loading[item.id]"
                    icon-class="ion-close-circled"
                    button-class="link hollow grey-btn"
                    @click="openDelete(item)"
                  />
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
              $t('INBOX_MGMT.SIDEBAR_TXT'),
              globalConfig.installationName
            )
          "
        />
      </div>
    </div>
    <settings
      v-if="showSettings"
      :show.sync="showSettings"
      :on-close="closeSettings"
      :inbox="selectedInbox"
    />

    <woot-delete-modal
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
import Settings from './Settings';
import adminMixin from '../../../../mixins/isAdmin';
import accountMixin from '../../../../mixins/account';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  components: {
    Settings,
  },
  mixins: [adminMixin, accountMixin, globalConfigMixin],
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
      inboxesList: 'inboxes/getInboxes',
      globalConfig: 'globalConfig/get',
    }),
    // Delete Modal
    deleteConfirmText() {
      return `${this.$t('INBOX_MGMT.DELETE.CONFIRM.YES')} ${
        this.selectedInbox.name
      }`;
    },
    deleteRejectText() {
      return `${this.$t('INBOX_MGMT.DELETE.CONFIRM.NO')} ${
        this.selectedInbox.name
      }`;
    },
    deleteMessage() {
      return `${this.$t('INBOX_MGMT.DELETE.CONFIRM.MESSAGE')} ${
        this.selectedInbox.name
      } ?`;
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
    async deleteInbox({ id }) {
      try {
        await this.$store.dispatch('inboxes/delete', id);
        bus.$emit(
          'newToastMessage',
          this.$t('INBOX_MGMT.DELETE.API.SUCCESS_MESSAGE')
        );
      } catch (error) {
        bus.$emit(
          'newToastMessage',
          this.$t('INBOX_MGMT.DELETE.API.ERROR_MESSAGE')
        );
      }
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
