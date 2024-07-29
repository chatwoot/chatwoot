<template>
  <div class="flex-1 overflow-auto">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-top"
      icon="add-circle"
      @click="openAddPopup"
    >
      {{ $t('LABEL_MGMT.HEADER_BTN_TXT') }}
    </woot-button>
    <div class="flex flex-row gap-4 p-8">
      <div class="w-full xl:w-3/5">
        <p
          v-if="!uiFlags.isFetching && !records.length"
          class="flex flex-col items-center justify-center h-full"
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
              <td class="label-title">
                <span class="overflow-hidden whitespace-nowrap text-ellipsis">{{
                  label.title
                }}</span>
              </td>
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
                />
                <woot-button
                  v-tooltip.top="$t('LABEL_MGMT.FORM.DELETE')"
                  variant="smooth"
                  color-scheme="alert"
                  size="tiny"
                  icon="dismiss-circle"
                  class-names="grey-btn"
                  :is-loading="loading[label.id]"
                  @click="openDeletePopup(label, index)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="hidden w-1/3 xl:block">
        <span v-dompurify-html="$t('LABEL_MGMT.SIDEBAR_TXT')" />
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
      :message="$t('LABEL_MGMT.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';

import AddLabel from './AddLabel.vue';
import EditLabel from './EditLabel.vue';

export default {
  components: {
    AddLabel,
    EditLabel,
  },
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
      return this.$t('LABEL_MGMT.DELETE.CONFIRM.YES');
    },
    deleteRejectText() {
      return this.$t('LABEL_MGMT.DELETE.CONFIRM.NO');
    },
    deleteMessage() {
      return ` ${this.selectedResponse.title}?`;
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
          useAlert(this.$t('LABEL_MGMT.DELETE.API.SUCCESS_MESSAGE'));
        })
        .catch(() => {
          useAlert(this.$t('LABEL_MGMT.DELETE.API.ERROR_MESSAGE'));
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
  @apply flex items-center;
}

.label-color--display {
  @apply rounded h-4 w-4 mr-1 rtl:mr-0 rtl:ml-1 border border-solid border-slate-50 dark:border-slate-700;
}

.label-title {
  span {
    @apply w-60 inline-block;
  }
}
</style>
