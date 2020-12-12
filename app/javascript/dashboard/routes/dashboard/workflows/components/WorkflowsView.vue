<template>
<div>
    <div class="settings-header">
      <h1 class="page-title">
        <span>{{ $t('WORKFLOWS_PAGE.HEADER') }}</span>
      </h1>
    </div>

  <div class="column content-box">
    <button
      class="button nice icon success button--fixed-right-top"
    >
      <i class="icon ion-android-add-circle"></i>
      {{ $t('WORKFLOWS_PAGE.HEADER_BTN_TXT') }}
    </button>
    <!-- List Canned Response -->
    <div class="row">
      <div class="small-8 columns">
        <p
          v-if="!uiFlags.fetchingList && !records.length"
          class="no-items-error-message"
        >
          {{ $t('WORKFLOWS_PAGE.LIST.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.fetchingList"
          :message="$t('WORKFLOWS_PAGE.LOADING')"
        />

        <table
          v-if="!uiFlags.fetchingList && records.length"
          class="woot-table"
        >
          <tbody>
            <tr
              v-for="(workflowAccountTemplate, index) in records"
              :key="workflowAccountTemplate.id"
            >
              <!-- Short Code  -->
                <td>
                  <span>
                  <b>{{ workflowAccountTemplate.name }}</b>
                  <br />{{ workflowAccountTemplate.description }}</span
                  >
                </td>
              <!-- Content -->
              <td>
               <span
              v-for="(inbox, index) in workflowAccountTemplate.inboxes"
              :key="inbox.id"
            >{{ inbox.name }}</span>

              </td>
              <!-- Action Buttons -->
              <td class="button-wrapper">
                <div @click="openEditPopup(workflowAccountTemplate)">
                  <woot-submit-button
                    :button-text="$t('WORKFLOWS_PAGE.EDIT.BUTTON_TEXT')"
                    icon-class="ion-edit"
                    button-class="link hollow grey-btn"
                  />
                </div>
                <div @click="openDeletePopup(workflowAccountTemplate, index)">
                  <woot-submit-button
                    :button-text="$t('WORKFLOWS_PAGE.DELETE.BUTTON_TEXT')"
                    :loading="loading[workflowAccountTemplate.id]"
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
        <span v-html="$t('WORKFLOWS_PAGE.SIDEBAR_TXT')"></span>
      </div>
    </div>
  </div>

</div>
</template>
<script>
/* global bus */
import { mapGetters } from 'vuex';


export default {
  data() {
    return {
      loading: {},
      showAddPopup: false,
      showEditPopup: false,
      showDeleteConfirmationPopup: false,
      selectedResponse: {},
      cannedResponseAPI: {
        message: '',
      },
    };
  },
  computed: {
    ...mapGetters({
      records: 'workflowAccountTemplates/getAccountWorkflowTemplates',
      uiFlags: 'workflowAccountTemplates/getUIFlags',
    }),
    // Delete Modal
    deleteConfirmText() {
      return `${this.$t('WORKFLOWS_PAGE.DELETE.CONFIRM.YES')} ${
        this.selectedResponse.short_code
      }`;
    },
    deleteRejectText() {
      return `${this.$t('WORKFLOWS_PAGE.DELETE.CONFIRM.NO')} ${
        this.selectedResponse.short_code
      }`;
    },
    deleteMessage() {
      return `${this.$t('WORKFLOWS_PAGE.DELETE.CONFIRM.MESSAGE')} ${
        this.selectedResponse.short_code
      } ?`;
    },
  },
  mounted() {
    // Fetch API Call
    this.$store.dispatch(
      'workflowAccountTemplates/getAccountWorkflowTemplates'
    );
  },
  methods: {
    showAlert(message) {
      // Reset loading, current selected agent
      this.loading[this.selectedResponse.id] = false;
      this.selectedResponse = {};
      // Show message
      this.cannedResponseAPI.message = message;
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
      this.deleteCannedResponse(this.selectedResponse.id);
    },
    deleteCannedResponse(id) {
      this.$store
        .dispatch('deleteCannedResponse', id)
        .then(() => {
          this.showAlert(this.$t('WORKFLOWS_PAGE.DELETE.API.SUCCESS_MESSAGE'));
        })
        .catch(() => {
          this.showAlert(this.$t('WORKFLOWS_PAGE.DELETE.API.ERROR_MESSAGE'));
        });
    },
  },
};
</script>
