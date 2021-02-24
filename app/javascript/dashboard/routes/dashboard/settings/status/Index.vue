<template>
  <div class="column content-box">
    <button
      class="button nice icon success button--fixed-right-top"
      @click="openAddPopup()"
    >
      <i class="icon ion-android-add-circle"></i>
      {{ $t('STATUS_MGMT.HEADER_BTN_TXT') }}
    </button>
    <!-- List Status Response -->
    <div class="row">
      <div class="small-8 columns">
        <p
          v-if="!uiFlags.fetchingList && !records.length"
          class="no-items-error-message"
        >
          {{ $t('STATUS_MGMT.LIST.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.fetchingList"
          :message="$t('STATUS_MGMT.LOADING')"
        />

        <table
          v-if="!uiFlags.fetchingList && records.length"
          class="woot-table"
        >
          <thead>
            <!-- Header -->
            <th
              v-for="thHeader in $t('STATUS_MGMT.LIST.TABLE_HEADER')"
              :key="thHeader"
            >
              {{ thHeader }}
            </th>
          </thead>
          <tbody>
            <tr v-for="(StatusItem, index) in records" :key="StatusItem.name">
              <!-- Content -->
              <td>{{ StatusItem.name }}</td>
              <!-- Action Buttons -->
              <td class="button-wrapper">
                <div @click="openEditPopup(StatusItem)">
                  <woot-submit-button
                    :button-text="$t('STATUS_MGMT.EDIT.BUTTON_TEXT')"
                    icon-class="ion-edit"
                    button-class="link hollow grey-btn"
                  />
                </div>
                <div @click="openDeletePopup(StatusItem, index)">
                  <woot-submit-button
                    :button-text="$t('STATUS_MGMT.DELETE.BUTTON_TEXT')"
                    :loading="loading[StatusItem.id]"
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
        <span v-html="$t('STATUS_MGMT.SIDEBAR_TXT')"></span>
      </div>
    </div>
    <!-- Add Agent -->
    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <add-Status :on-close="hideAddPopup" />
    </woot-modal>

    <!-- Edit Status Response -->
    <woot-modal :show.sync="showEditPopup" :on-close="hideEditPopup">
      <edit-Status
        v-if="showEditPopup"
        :id="selectedResponse.id"
        :edshort-code="selectedResponse.short_code"
        :edcontent="selectedResponse.content"
        :on-close="hideEditPopup"
      />
    </woot-modal>

    <!-- Delete Status Response -->
    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('STATUS_MGMT.DELETE.CONFIRM.TITLE')"
      :message="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />
  </div>
</template>
<script>
/* global bus */
import { mapGetters } from 'vuex';

import AddStatus from './AddStatus';
import EditStatus from './EditStatus';

export default {
  components: {
    AddStatus,
    EditStatus,
  },
  data() {
    return {
      loading: {},
      showAddPopup: false,
      showEditPopup: false,
      showDeleteConfirmationPopup: false,
      selectedResponse: {},
      StatusAPI: {
        message: '',
      },
    };
  },
  computed: {
    ...mapGetters({
      records: 'getStatus',
      uiFlags: 'getUIFlags',
    }),
    // Delete Modal
    deleteConfirmText() {
      return `${this.$t('STATUS_MGMT.DELETE.CONFIRM.YES')} ${
        this.selectedResponse.short_code
      }`;
    },
    deleteRejectText() {
      return `${this.$t('STATUS_MGMT.DELETE.CONFIRM.NO')} ${
        this.selectedResponse.short_code
      }`;
    },
    deleteMessage() {
      return `${this.$t('STATUS_MGMT.DELETE.CONFIRM.MESSAGE')} ${
        this.selectedResponse.short_code
      } ?`;
    },
  },
  mounted() {
    // Fetch API Call
    this.$store.dispatch('getStatus');
  },
  methods: {
    showAlert(message) {
      // Reset loading, current selected agent
      this.loading[this.selectedResponse.id] = false;
      this.selectedResponse = {};
      // Show message
      this.StatusAPI.message = message;
      bus.$emit('newToastMessage', message);
    },
    // Edit Function
    openAddPopup() {
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
    },

    // Edit Modal Functions
    openEditPopup(response) {
      this.showEditPopup = true;
      this.selectedResponse = response;
    },
    hideEditPopup() {
      this.showEditPopup = false;
    },

    // Delete Modal Functions
    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedResponse = response;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    // Set loading and call Delete API
    confirmDeletion() {
      this.loading[this.selectedResponse.id] = true;
      this.closeDeletePopup();
      this.deleteStatus(this.selectedResponse.id);
    },
    deleteStatus(id) {
      this.$store
        .dispatch('deleteStatus', id)
        .then(() => {
          this.showAlert(this.$t('STATUS_MGMT.DELETE.API.SUCCESS_MESSAGE'));
        })
        .catch(() => {
          this.showAlert(this.$t('STATUS_MGMT.DELETE.API.ERROR_MESSAGE'));
        });
    },
  },
};
</script>
