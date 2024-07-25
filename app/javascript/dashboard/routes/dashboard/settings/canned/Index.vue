<template>
  <div class="flex-1 overflow-auto">
    <woot-button
      color-scheme="success"
      class-names="button--fixed-top"
      icon="add-circle"
      @click="openAddPopup()"
    >
      {{ $t('CANNED_MGMT.HEADER_BTN_TXT') }}
    </woot-button>

    <!-- List Canned Response -->
    <div class="flex flex-row gap-4 p-8">
      <div class="w-full xl:w-3/5">
        <p
          v-if="!uiFlags.fetchingList && !records.length"
          class="flex flex-col items-center justify-center h-full"
        >
          {{ $t('CANNED_MGMT.LIST.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.fetchingList"
          :message="$t('CANNED_MGMT.LOADING')"
        />

        <table
          v-if="!uiFlags.fetchingList && records.length"
          class="woot-table"
        >
          <thead>
            <!-- Header -->
            <th
              v-for="thHeader in $t('CANNED_MGMT.LIST.TABLE_HEADER')"
              :key="thHeader"
              class="last:text-right first:m-0 first:p-0"
            >
              <p v-if="thHeader !== $t('CANNED_MGMT.LIST.TABLE_HEADER[0]')">
                {{ thHeader }}
              </p>

              <button
                v-if="thHeader === $t('CANNED_MGMT.LIST.TABLE_HEADER[0]')"
                class="flex items-center p-0 cursor-pointer"
                @click="toggleSort"
              >
                <p class="uppercase">
                  {{ thHeader }}
                </p>
                <fluent-icon
                  class="mb-2 ml-2"
                  :icon="sortOrder === 'asc' ? 'chevron-up' : 'chevron-down'"
                />
              </button>
            </th>
          </thead>
          <tbody>
            <tr
              v-for="(cannedItem, index) in records"
              :key="cannedItem.short_code"
            >
              <!-- Short Code  -->
              <td
                class="w-[8.75rem] truncate max-w-[8.75rem]"
                :title="cannedItem.short_code"
              >
                {{ cannedItem.short_code }}
              </td>
              <!-- Content -->
              <td class="break-all whitespace-normal">
                {{ cannedItem.content }}
              </td>
              <!-- Action Buttons -->
              <td class="flex justify-end gap-1 min-w-[12.5rem]">
                <woot-button
                  v-tooltip.top="$t('CANNED_MGMT.EDIT.BUTTON_TEXT')"
                  variant="smooth"
                  size="tiny"
                  color-scheme="secondary"
                  icon="edit"
                  @click="openEditPopup(cannedItem)"
                />
                <woot-button
                  v-tooltip.top="$t('CANNED_MGMT.DELETE.BUTTON_TEXT')"
                  variant="smooth"
                  color-scheme="alert"
                  size="tiny"
                  icon="dismiss-circle"
                  class-names="grey-btn"
                  :is-loading="loading[cannedItem.id]"
                  @click="openDeletePopup(cannedItem, index)"
                />
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="hidden w-1/3 xl:block">
        <span v-dompurify-html="$t('CANNED_MGMT.SIDEBAR_TXT')" />
      </div>
    </div>
    <!-- Add Agent -->
    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <add-canned :on-close="hideAddPopup" />
    </woot-modal>

    <!-- Edit Canned Response -->
    <woot-modal :show.sync="showEditPopup" :on-close="hideEditPopup">
      <edit-canned
        v-if="showEditPopup"
        :id="selectedResponse.id"
        :edshort-code="selectedResponse.short_code"
        :edcontent="selectedResponse.content"
        :on-close="hideEditPopup"
      />
    </woot-modal>

    <!-- Delete Canned Response -->
    <woot-delete-modal
      :show.sync="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('CANNED_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('CANNED_MGMT.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import AddCanned from './AddCanned.vue';
import EditCanned from './EditCanned.vue';

export default {
  components: {
    AddCanned,
    EditCanned,
  },
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
      sortOrder: 'asc',
    };
  },
  computed: {
    ...mapGetters({
      records: 'getCannedResponses',
      uiFlags: 'getUIFlags',
    }),
    // Delete Modal
    deleteConfirmText() {
      return `${this.$t('CANNED_MGMT.DELETE.CONFIRM.YES')} ${
        this.selectedResponse.short_code
      }`;
    },
    deleteRejectText() {
      return `${this.$t('CANNED_MGMT.DELETE.CONFIRM.NO')} ${
        this.selectedResponse.short_code
      }`;
    },
    deleteMessage() {
      return ` ${this.selectedResponse.short_code}?`;
    },
  },
  mounted() {
    // Fetch API Call
    this.$store.dispatch('getCannedResponse').then(() => {
      this.toggleSort();
    });
  },
  methods: {
    toggleSort() {
      this.records.sort((a, b) => {
        if (this.sortOrder === 'asc') {
          return a.short_code.localeCompare(b.short_code);
        }
        return b.short_code.localeCompare(a.short_code);
      });
      this.sortOrder = this.sortOrder === 'asc' ? 'desc' : 'asc';
    },
    showAlertMessage(message) {
      // Reset loading, current selected agent
      this.loading[this.selectedResponse.id] = false;
      this.selectedResponse = {};
      // Show message
      this.cannedResponseAPI.message = message;
      useAlert(message);
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
          this.showAlertMessage(
            this.$t('CANNED_MGMT.DELETE.API.SUCCESS_MESSAGE')
          );
        })
        .catch(error => {
          const errorMessage =
            error?.message || this.$t('CANNED_MGMT.DELETE.API.ERROR_MESSAGE');
          this.showAlertMessage(errorMessage);
        });
    },
  },
};
</script>
