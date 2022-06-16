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
      <div class="small-8 columns with-right-space">
        <p
          v-if="!uiFlags.isFetching && !records.length"
          class="no-items-error-message"
        >
          {{ $t('AUTOMATION.LIST.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.isFetching"
          :message="$t('AUTOMATION.LOADING')"
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
            <tr v-for="(automation, index) in records" :key="index">
              <td>{{ automation.name }}</td>
              <td>{{ automation.description }}</td>
              <td>
                <woot-switch
                  :value="automation.active"
                  @input="toggleAutomation(automation, automation.active)"
                />
              </td>
              <td>{{ readableTime(automation.created_on) }}</td>
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
                />
                <woot-button
                  v-tooltip.top="$t('AUTOMATION.CLONE.TOOLTIP')"
                  variant="smooth"
                  size="tiny"
                  color-scheme="primary"
                  class-names="grey-btn"
                  :is-loading="loading[automation.id]"
                  icon="copy"
                  @click="cloneAutomation(automation.id)"
                />
                <woot-button
                  v-tooltip.top="$t('AUTOMATION.FORM.DELETE')"
                  variant="smooth"
                  color-scheme="alert"
                  size="tiny"
                  icon="dismiss-circle"
                  class-names="grey-btn"
                  :is-loading="loading[automation.id]"
                  @click="openDeletePopup(automation, index)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="small-4 columns">
        <span v-dompurify-html="$t('AUTOMATION.SIDEBAR_TXT')" />
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
        @saveAutomation="submitAutomation"
      />
    </woot-modal>

    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('LABEL_MGMT.DELETE.CONFIRM.TITLE')"
      :message="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />

    <woot-modal
      :show.sync="showEditPopup"
      size="medium"
      :on-close="hideEditPopup"
    >
      <edit-automation-rule
        v-if="showEditPopup"
        :on-close="hideEditPopup"
        :selected-response="selectedResponse"
        @saveAutomation="submitAutomation"
      />
    </woot-modal>
    <woot-confirm-modal
      ref="confirmDialog"
      :title="toggleModalTitle"
      :description="toggleModalDescription"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import AddAutomationRule from './AddAutomationRule.vue';
import EditAutomationRule from './EditAutomationRule.vue';
import alertMixin from 'shared/mixins/alertMixin';
import timeMixin from 'dashboard/mixins/time';

export default {
  components: {
    AddAutomationRule,
    EditAutomationRule,
  },
  mixins: [alertMixin, timeMixin],
  data() {
    return {
      loading: {},
      showAddPopup: false,
      showEditPopup: false,
      showDeleteConfirmationPopup: false,
      selectedResponse: {},
      toggleModalTitle: this.$t('AUTOMATION.TOGGLE.ACTIVATION_TITLE'),
      toggleModalDescription: this.$t(
        'AUTOMATION.TOGGLE.ACTIVATION_DESCRIPTION'
      ),
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
        this.selectedResponse.name
      }`;
    },
    deleteRejectText() {
      return `${this.$t('AUTOMATION.DELETE.CONFIRM.NO')} ${
        this.selectedResponse.name
      }`;
    },
    deleteMessage() {
      return `${this.$t('AUTOMATION.DELETE.CONFIRM.MESSAGE')} ${
        this.selectedResponse.name
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
      this.selectedResponse = response;
      this.showEditPopup = true;
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
    async deleteAutomation(id) {
      try {
        await this.$store.dispatch('automations/delete', id);
        this.showAlert(this.$t('AUTOMATION.DELETE.API.SUCCESS_MESSAGE'));
        this.loading[this.selectedResponse.id] = false;
      } catch (error) {
        this.showAlert(this.$t('AUTOMATION.DELETE.API.ERROR_MESSAGE'));
      }
    },
    async cloneAutomation(id) {
      try {
        await this.$store.dispatch('automations/clone', id);
        this.showAlert(this.$t('AUTOMATION.CLONE.API.SUCCESS_MESSAGE'));
        this.$store.dispatch('automations/get');
        this.loading[this.selectedResponse.id] = false;
      } catch (error) {
        this.showAlert(this.$t('AUTOMATION.CLONE.API.ERROR_MESSAGE'));
      }
    },
    async submitAutomation(payload, mode) {
      try {
        const action =
          mode === 'EDIT' ? 'automations/update' : 'automations/create';
        const successMessage =
          mode === 'EDIT'
            ? this.$t('AUTOMATION.EDIT.API.SUCCESS_MESSAGE')
            : this.$t('AUTOMATION.ADD.API.SUCCESS_MESSAGE');
        await await this.$store.dispatch(action, payload);
        this.showAlert(this.$t(successMessage));
        this.hideAddPopup();
        this.hideEditPopup();
      } catch (error) {
        const errorMessage =
          mode === 'EDIT'
            ? this.$t('AUTOMATION.EDIT.API.ERROR_MESSAGE')
            : this.$t('AUTOMATION.ADD.API.ERROR_MESSAGE');
        this.showAlert(errorMessage);
      }
    },
    async toggleAutomation(automation, status) {
      try {
        this.toggleModalTitle = status
          ? this.$t('AUTOMATION.TOGGLE.DEACTIVATION_TITLE')
          : this.$t('AUTOMATION.TOGGLE.ACTIVATION_TITLE');
        this.toggleModalDescription = status
          ? this.$t('AUTOMATION.TOGGLE.DEACTIVATION_DESCRIPTION', {
              automationName: automation.name,
            })
          : this.$t('AUTOMATION.TOGGLE.ACTIVATION_DESCRIPTION', {
              automationName: automation.name,
            });
        // Check if user confirms to proceed
        const ok = await this.$refs.confirmDialog.showConfirmation();
        if (ok) {
          await await this.$store.dispatch('automations/update', {
            id: automation.id,
            active: !status,
          });
          const message = status
            ? this.$t('AUTOMATION.TOGGLE.DEACTIVATION_SUCCESFUL')
            : this.$t('AUTOMATION.TOGGLE.ACTIVATION_SUCCESFUL');
          this.showAlert(message);
        }
      } catch (error) {
        this.showAlert(this.$t('AUTOMATION.EDIT.API.ERROR_MESSAGE'));
      }
    },
    readableTime(date) {
      return this.messageStamp(new Date(date), 'LLL d, h:mm a');
    },
  },
};
</script>

<style scoped>
.automation__status-checkbox {
  margin: 0;
}
</style>
