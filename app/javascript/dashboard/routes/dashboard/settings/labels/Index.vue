<template>
  <div class="column content-box">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-right-top"
      icon="add-circle"
      @click="openAddPopup"
    >
      {{ $t('LABEL_MGMT.HEADER_BTN_TXT') }}
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
              v-for="thHeader in $t('LABEL_MGMT.LIST.TABLE_HEADER')"
              :key="thHeader"
            >
              {{ thHeader }}
            </th>
          </thead>
          <tbody>
            <tr v-for="(label, index) in records" :key="label.title">
              <td>{{ label.title }}</td>
              <td>{{ label.description }}</td>
              <td>
                <div class="label-color--container">
                  <span
                    class="label-color--display"
                    :style="{ backgroundColor: label.color }"
                  />
                  {{ label.color }}
                </div>
              </td>
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
        <span v-html="$t('LABEL_MGMT.SIDEBAR_TXT')"></span>
      </div>
    </div>
    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <add-label @close="hideAddPopup" />
    </woot-modal>

    <woot-modal :show.sync="showEditPopup" :on-close="hideEditPopup">
      <edit-label
        :selected-response="selectedResponse"
        @close="hideEditPopup"
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
  </div>
</template>
<script>
import { mapGetters } from 'vuex';

import AddLabel from './AddLabel';
import EditLabel from './EditLabel';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    AddLabel,
    EditLabel,
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
  },
};
</script>

<style scoped lang="scss">
@import '~dashboard/assets/scss/variables';

.label-color--container {
  display: flex;
  align-items: center;
}

.label-color--display {
  border-radius: $space-smaller;
  height: $space-normal;
  margin-right: $space-smaller;
  width: $space-normal;
}
</style>
