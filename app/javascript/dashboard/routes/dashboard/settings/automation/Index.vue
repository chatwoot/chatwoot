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
          v-if="!uiFlags.isFetching && !records.data.length"
          class="no-items-error-message"
        >
          {{ $t('AUTOMATION.LIST.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.isFetching"
          :message="$t('AUTOMATION.LOADING')"
        />
        <table
          v-if="!uiFlags.isFetching && records.data.length"
          class="woot-table"
        >
          <thead>
            <th
              v-for="thHeader in $t('AUTOMATION.LIST.TABLE_HEADER')"
              :key="thHeader"
            >
              {{ thHeader }}
            </th>
          </thead>
          <tbody>
            <tr
              v-for="(automation, index) in records.data"
              :key="automation.title"
            >
              <td>{{ automation.name }}</td>
              <td>{{ automation.description }}</td>
              <td>
                <input
                  type="checkbox"
                  checked
                  value="enabled"
                  name="enabled"
                  class="automation__status-checkbox"
                />
              </td>
              <td>2 Jan 2022</td>
              <td class="button-wrapper">
                <woot-button
                  v-tooltip.top="$t('AUTOMATION.FORM.EDIT')"
                  variant="smooth"
                  size="tiny"
                  color-scheme="secondary"
                  class-names="grey-btn"
                  :is-loading="loading[automation.id]"
                  icon="edit"
                  @click="openEditPopup(automation)"
                >
                </woot-button>
                <woot-button
                  v-tooltip.top="$t('AUTOMATION.FORM.DELETE')"
                  variant="smooth"
                  color-scheme="alert"
                  size="tiny"
                  icon="dismiss-circle"
                  class-names="grey-btn"
                  :is-loading="loading[automation.id]"
                  @click="openDeletePopup(automation, index)"
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
      records: ['automations/getAutomations'],
      uiFlags: 'automations/getUIFlags',
    }),
    // Delete Modal
    deleteConfirmText() {
      return `${this.$t('AUTOMATION.DELETE.CONFIRM.YES')} ${
        this.selectedResponse.title
      }`;
    },
    deleteRejectText() {
      return `${this.$t('AUTOMATION.DELETE.CONFIRM.NO')} ${
        this.selectedResponse.title
      }`;
    },
    deleteMessage() {
      return `${this.$t('AUTOMATION.DELETE.CONFIRM.MESSAGE')} ${
        this.selectedResponse.title
      } ?`;
    },
  },
  mounted() {
    this.$store.dispatch('automations/get');
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
      this.deleteAutomation(this.selectedResponse.id);
    },
    deleteAutomation(id) {
      this.$store
        .dispatch('automation/delete', id)
        .then(() => {
          this.showAlert(this.$t('AUTOMATION.DELETE.API.SUCCESS_MESSAGE'));
        })
        .catch(() => {
          this.showAlert(this.$t('AUTOMATION.DELETE.API.ERROR_MESSAGE'));
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

<style scoped>
.automation__status-checkbox {
  margin: 0;
}
</style>
