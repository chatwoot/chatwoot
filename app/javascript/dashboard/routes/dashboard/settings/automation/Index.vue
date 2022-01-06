<template>
  <div class="column content-box">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-right-top"
      icon="add-circle"
      @click="openAddPopup()"
    >
      {{ $t('AUTOMATION.HEADER_BTN_TXT') }}
    </woot-button>
    <div class="row">
      <div class="small-8 columns with-right-space ">
        <p
          v-if="!uiFlags.isFetching && !records.length"
          class="no-items-error-message"
        >
          {{ $t('LABEL_MGMT.LIST.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.isFetching"
          :message="$t('LABEL_MGMT.LOADING')"
        />
        <table v-if="!uiFlags.isFetching && records.length" class="woot-table">
          <thead>
            <th
              v-for="thHeader in $t('AUTOMATION.LIST.TABLE_HEADER')"
              :key="thHeader"
            >
              {{ thHeader }}
            </th>
          </thead>
          <tbody>
            <tr v-for="(label, index) in records" :key="label.title">
              <td>{{ label.title }}</td>
              <td>{{ label.description }}</td>
              <td>44</td>
              <td>2 Jan 2022</td>
              <td class="button-wrapper">
                <woot-button
                  v-tooltip.top="$t('LABEL_MGMT.FORM.EDIT')"
                  variant="smooth"
                  size="tiny"
                  color-scheme="secondary"
                  class-names="grey-btn"
                  :is-loading="loading[label.id]"
                  icon="edit"
                  @click="openEditPopup(label)"
                >
                </woot-button>
                <woot-button
                  v-tooltip.top="$t('LABEL_MGMT.FORM.DELETE')"
                  variant="smooth"
                  color-scheme="alert"
                  size="tiny"
                  icon="dismiss-circle"
                  class-names="grey-btn"
                  :is-loading="loading[label.id]"
                  @click="openDeletePopup(label, index)"
                >
                </woot-button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="small-4 columns">
        <span v-html="$t('AUTOMATION.SIDEBAR_TXT')"></span>
      </div>
    </div>
    <woot-modal
      :show.sync="showAddPopup"
      size="medium"
      :on-close="hideAddPopup"
    >
      <add-automation-rule
        v-if="showAddPopup"
        :on-close="hideAddPopup"
        @applyFilter="onCreateAutomation"
      />
    </woot-modal>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import AddAutomationRule from './AddAutomationRule.vue';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    AddAutomationRule,
  },
  mixins: [alertMixin],
  data() {
    return {
      loading: {},
      showAddPopup: false,
      showEditPopup: false,
      showDeleteConfirmationPopup: false,
      selectedResponse: {},
    };
  },
  computed: {
    ...mapGetters({
      records: 'labels/getLabels',
      uiFlags: 'labels/getUIFlags',
    }),
    // Delete Modal
    deleteConfirmText() {
      return `${this.$t('LABEL_MGMT.DELETE.CONFIRM.YES')} ${
        this.selectedResponse.title
      }`;
    },
    deleteRejectText() {
      return `${this.$t('LABEL_MGMT.DELETE.CONFIRM.NO')} ${
        this.selectedResponse.title
      }`;
    },
    deleteMessage() {
      return `${this.$t('LABEL_MGMT.DELETE.CONFIRM.MESSAGE')} ${
        this.selectedResponse.title
      } ?`;
    },
  },
  mounted() {
    this.$store.dispatch('labels/get');
  },
  methods: {
    openAddPopup() {
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
    },
    openEditPopup(response) {
      this.showEditPopup = true;
      this.selectedResponse = response;
    },
    hideEditPopup() {
      this.showEditPopup = false;
    },
    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedResponse = response;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    confirmDeletion() {
      this.loading[this.selectedResponse.id] = true;
      this.closeDeletePopup();
      this.deleteLabel(this.selectedResponse.id);
    },
    deleteLabel(id) {
      this.$store
        .dispatch('labels/delete', id)
        .then(() => {
          this.showAlert(this.$t('LABEL_MGMT.DELETE.API.SUCCESS_MESSAGE'));
        })
        .catch(() => {
          this.showAlert(this.$t('LABEL_MGMT.DELETE.API.ERROR_MESSAGE'));
        })
        .finally(() => {
          this.loading[this.selectedResponse.id] = false;
        });
    },
    async onCreateAutomation(payload) {
      // This is a test action to send the automation data to the server
      this.$store.dispatch('automations/create', payload);
    },
  },
};
</script>
