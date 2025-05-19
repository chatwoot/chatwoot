<script>
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import ReportMetricCard from './ReportMetricCard.vue';
import { defineComponent } from 'vue';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';

export default defineComponent({
  name: 'CampaignReportModal',
  components: {
    PaginationFooter,
    ReportMetricCard,
  },
  props: {
    campaign: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      processedContacts: [],
      failedContacts: [],
      readContacts: [],
      deliveredContacts: [],
      repliedContacts: [],
      pendingContacts: [],
      isLoading: true,
      error: null,
      rowsPerPage: 25,
      currentPage: 1,
      searchQuery: '',
      activeTab: 'processed',
      contactTypes: [
        { key: 'processed', label: 'Successful Contacts' },
        { key: 'read', label: 'Read Contacts' },
        { key: 'replied', label: 'Replied Contacts' },
        { key: 'delivered', label: 'Delivered Contacts' },
        { key: 'failed', label: 'Failed Contacts' },
        { key: 'pending', label: 'Pending Contacts' },
      ],
      sortConfig: {
        key: null,
        direction: 'asc',
      },
      batchSize: 100,
      metrics: {
        sent: 0,
        delivered: 0,
        read: 0,
        replied: 0,
        failed: 0,
        processing: 0,
        queued: 0,
      },
    };
  },
  computed: {
    ...mapGetters({
      contactDetails: 'campaigns/getContactsForCampaign',
    }),
    filteredProcessedContacts() {
      return this.filterAndSearchContacts(this.processedContacts);
    },
    filteredReadContacts() {
      return this.filterAndSearchContacts(this.readContacts);
    },
    filteredDeliveredContacts() {
      return this.filterAndSearchContacts(this.deliveredContacts);
    },
    filteredRepliedContacts() {
      return this.filterAndSearchContacts(this.repliedContacts);
    },
    filteredPendingContacts() {
      return this.filterAndSearchContacts(this.pendingContacts);
    },
    filteredFailedContacts() {
      return this.filterAndSearchContacts(this.failedContacts);
    },
    totalProcessedCount() {
      return this.processedContacts.length;
    },
    totalFailedCount() {
      return this.failedContacts.length;
    },
    totalContacts() {
      return this.processedContacts.length + this.failedContacts.length;
    },
    totalPendingContacts() {
      return this.pendingContacts.length;
    },
    activeContacts() {
      switch (this.activeTab) {
        case 'processed':
          return this.filteredProcessedContacts;
        case 'read':
          return this.filteredReadContacts;
        case 'delivered':
          return this.filteredDeliveredContacts;
        case 'replied':
          return this.filteredRepliedContacts;
        case 'pending':
          return this.filteredPendingContacts;
        case 'failed':
          return this.filteredFailedContacts;
        default:
          return [];
      }
    },
    visibleContacts() {
      const startIdx = (this.currentPage - 1) * this.rowsPerPage;
      const endIdx = Math.min(
        this.activeContacts.length,
        this.currentPage * this.rowsPerPage
      );
      return this.activeContacts.slice(startIdx, endIdx);
    },
  },
  mounted() {
    this.$store
      .dispatch('campaigns/fetchCampaignContacts', this.campaign.display_id)
      .then(() => {
        this.fetchCampaignContacts();
      })
      .catch(error => {
        this.isLoading = false;
        this.error =
          error.message || this.$t('CAMPAIGN.WHATSAPP.REPORT.GENERIC_ERROR');
        this.$emit('error', error);
      });
  },
  methods: {
    fetchCampaignContacts() {
      this.isLoading = true;
      this.error = null;

      try {
        const contacts = this.contactDetails(this.campaign.display_id);
        console.log(contacts);

        this.repliedContacts = [...(contacts.replied_contacts || [])];
        this.pendingContacts = [...(contacts.pending_contacts || [])];
        this.failedContacts = contacts.failed_contacts || [];

        this.readContacts = [
          ...(contacts.read_contacts || []),
          ...(contacts.replied_contacts || []),
        ];

        this.deliveredContacts = [
          ...(contacts.delivered_contacts || []),
          ...(contacts.replied_contacts || []),
          ...(contacts.read_contacts || []),
        ];

        this.processedContacts = [
          ...(contacts.processed_contacts || []),
          ...(contacts.read_contacts || []),
          ...(contacts.delivered_contacts || []),
          ...(contacts.replied_contacts || []),
        ];

        this.updateMetrics(contacts);
        console.log('Processed:', contacts.processed_contacts);
      } catch (error) {
        this.error =
          error.message || this.$t('CAMPAIGN.WHATSAPP.REPORT.GENERIC_ERROR');
        this.$emit('error', error);
      } finally {
        this.isLoading = false;
      }
    },
    onUpdatePage(page) {
      this.currentPage = page;
    },
    updateMetrics(contacts) {
      const pending = contacts.pending_contacts || [];
      const processed = [
        ...(contacts.processed_contacts || []),
        ...(contacts.read_contacts || []),
        ...(contacts.delivered_contacts || []),
        ...(contacts.replied_contacts || []),
      ];
      const failed = contacts.failed_contacts || [];

      const read = [
        ...(contacts.read_contacts || []),
        ...(contacts.replied_contacts || []),
      ];
      const delivered = [
        ...(contacts.read_contacts || []),
        ...(contacts.delivered_contacts || []),
        ...(contacts.replied_contacts || []),
      ];
      const replied = contacts.replied_contacts || [];

      this.metrics = {
        sent: processed.length,
        delivered: delivered.length,
        read: read.length,
        replied: replied.length,
        failed: failed.length,
        processing: pending.length,
      };
    },
    filterAndSearchContacts(contacts) {
      if (!contacts) return [];
      const query = this.searchQuery.toLowerCase();
      return contacts.filter(
        contact =>
          contact.name.toLowerCase().includes(query) ||
          contact.phone_number.toLowerCase().includes(query)
      );
    },
    sortContacts(key) {
      if (this.sortConfig.key === key) {
        this.sortConfig.direction =
          this.sortConfig.direction === 'asc' ? 'desc' : 'asc';
      } else {
        this.sortConfig.key = key;
        this.sortConfig.direction = 'asc';
      }

      const multiplier = this.sortConfig.direction === 'asc' ? 1 : -1;
      const contacts =
        this.activeTab === 'processed'
          ? this.processedContacts
          : this.failedContacts;

      contacts.sort((a, b) => {
        if (a[key] < b[key]) return -1 * multiplier;
        if (a[key] > b[key]) return 1 * multiplier;
        return 0;
      });
    },
    async exportContacts() {
      try {
        const query = {
          payload: [{ campaign_id: this.campaign.display_id }],
        };
        await this.$store.dispatch('contacts/export', query);
        useAlert(
          this.$t(
            'CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.SUCCESS_MESSAGE'
          )
        );
      } catch (error) {
        useAlert(
          error.message ||
            this.$t(
              'CONTACTS_LAYOUT.HEADER.ACTIONS.EXPORT_CONTACT.ERROR_MESSAGE'
            )
        );
      }
    },
  },
});
</script>

<template>
  <!-- Modal Header -->

  <div
    class="flex-col lg:flex-row flex flex-wrap mx-0 shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2 px-6 py-8 gap-16 mt-6"
  >
    <p class="text-slate-500 dark:text-white text-lg">
      {{ $t('WHATSAPP_REPORTS.REPORT_TITLE', { title: campaign.title }) }}
    </p>
    <p class="text-lg text-slate-500 dark:text-white">
      {{
        $t('WHATSAPP_REPORTS.CONTACTS_COUNT', {
          count: totalContacts,
        })
      }}
    </p>
  </div>

  <!-- Modal Content -->
  <div v-if="isLoading" class="flex-grow flex items-center justify-center p-6">
    <div
      class="w-16 h-16 border-4 border-t-4 border-blue-600 border-solid rounded-full animate-spin"
    />
  </div>

  <div v-else-if="error" class="flex-grow flex items-center justify-center p-6">
    <div class="text-red-500">{{ error }}</div>
  </div>

  <div v-else class="flex-grow overflow-auto mt-8">
    <!-- Stats Grid -->
    <div
      class="grid sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-6 gap-4 mb-8"
    >
      <!-- Sent Messages -->
      <div class="metric-card">
        <div class="flex flex-col">
          <span class="text-xl font-bold text-blue-600">{{
            metrics.sent
          }}</span>
          <p class="text-xs text-slate-600 dark:text-white">Sent</p>
        </div>

        <woot-button
          icon="checkmark"
          size="medium"
          color-scheme="primary"
          class-names="button--only-icon"
        />
      </div>

      <!-- Delivered Messages -->
      <div class="metric-card">
        <div class="flex flex-col">
          <span class="text-xl font-bold text-blue-600">{{
            metrics.delivered
          }}</span>
          <p class="text-xs text-slate-600 dark:text-white">Delivered</p>
        </div>

        <woot-button
          icon="checkmark-double"
          size="medium"
          color-scheme="primary"
          class-names="button--only-icon"
        />
      </div>

      <!-- Read Messages -->
      <div class="metric-card">
        <div class="flex flex-col">
          <span class="text-xl font-bold text-blue-600">{{
            metrics.read
          }}</span>
          <p class="text-xs text-slate-600 dark:text-white">Read</p>
        </div>

        <woot-button
          icon="eye-show"
          size="medium"
          color-scheme="primary"
          class-names="button--only-icon"
        />
      </div>

      <!-- Replied Messages -->
      <div class="metric-card">
        <div class="flex flex-col">
          <span class="text-xl font-bold text-blue-600">{{
            metrics.replied
          }}</span>
          <p class="text-xs text-slate-600 dark:text-white">Replied</p>
        </div>

        <woot-button
          icon="arrow-reply"
          size="medium"
          color-scheme="primary"
          class-names="button--only-icon"
        />
      </div>

      <!-- Failed Messages -->
      <div class="metric-card">
        <div class="flex flex-col">
          <span class="text-xl font-bold text-blue-600">{{
            metrics.failed
          }}</span>
          <p class="text-xs text-slate-600 dark:text-white">Failed</p>
        </div>

        <woot-button
          icon="error-circle"
          size="medium"
          color-scheme="primary"
          class-names="button--only-icon"
        />
      </div>

      <!-- Processing Messages -->
      <div class="metric-card">
        <div class="flex flex-col">
          <span class="text-xl font-bold text-blue-600">{{
            metrics.processing
          }}</span>
          <p class="text-xs text-slate-600 dark:text-white">Processing</p>
        </div>

        <woot-button
          icon="repeat"
          size="medium"
          color-scheme="primary"
          class-names="button--only-icon"
        />
      </div>
    </div>
    <!-- Controls -->
    <div class="flex justify-between items-center mb-2">
      <div class="flex items-center space-x-4">
        <input
          v-model="searchQuery"
          type="text"
          :placeholder="$t('CAMPAIGN.WHATSAPP.REPORT.SEARCH_PLACEHOLDER')"
          class="px-4 w-96 py-2 border rounded-lg bg-white dark:bg-n-solid-3 dark:border-dark dark:text-dark-primary focus:outline-none"
        />
      </div>
      <div class="flex space-x-2 overflow-x-auto">
        <select
          v-model="activeTab"
          class="py-2 border rounded-lg dark:bg-n-solid-3 dark:border-dark dark:text-dark-primary"
        >
          <option
            v-for="type in contactTypes"
            :key="type.key"
            :value="type.key"
          >
            {{ type.label }}
          </option>
        </select>
      </div>
    </div>

    <!-- Table Container with Fixed Header and Scrollable Body -->

<!-- flex-col lg:flex-row  -->
    <div
      class="shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2 px-4 py-4 gap-16 mt-6"
    >
      <div class="overflow-x-auto bg-white dark:bg-n-solid-3 rounded-lg">
        <div class="max-h-[500px] overflow-y-auto">
          <table class="w-full">
            <thead class="sticky top-0 bg-white dark:bg-n-solid-3 z-10">
              <tr class="border-b dark:border-dark">
                <th
                  class="p-4 text-left font-medium text-slate-700 dark:text-white"
                >
                  <div
                    class="flex items-center cursor-pointer"
                    @click="sortContacts('name')"
                  >
                    Contact
                    <span
                      class="ml-2 text-xxs"
                      v-if="sortConfig.key === 'name'"
                    >
                      {{ sortConfig.direction === 'asc' ? '▲' : '▼' }}
                    </span>
                  </div>
                </th>
                <th
                  class="p-4 text-left font-medium text-slate-700 dark:text-white"
                >
                  <div
                    class="flex items-center cursor-pointer"
                    @click="sortContacts('phone_number')"
                  >
                    Phone
                    <span
                      class="ml-2 text-xxs"
                      v-if="sortConfig.key === 'phone_number'"
                    >
                      {{ sortConfig.direction === 'asc' ? '▲' : '▼' }}
                    </span>
                  </div>
                </th>
                <th
                  v-if="activeTab === 'failed'"
                  class="p-4 text-left font-medium text-slate-700 dark:text-white"
                >
                  <div class="flex items-center">Reason</div>
                </th>
                <th
                  class="p-4 text-left font-medium text-slate-700 dark:text-white"
                >
                  <div
                    class="flex items-center cursor-pointer"
                    @click="sortContacts('processed_at')"
                  >
                    Time

                    <span
                      class="ml-2 text-xxs"
                      v-if="sortConfig.key === 'processed_at'"
                    >
                      {{ sortConfig.direction === 'asc' ? '▲' : '▼' }}
                    </span>
                  </div>
                </th>
              </tr>
            </thead>
            <tbody>
              <tr
                v-for="contact in visibleContacts"
                :key="contact.id"
                class="border-b last:border-b-0 dark:border-dark hover:bg-slate-50 dark:hover:bg-n-solid-2"
              >
                <td class="p-4 text-slate-900 dark:text-white">
                  {{ contact.name }}
                </td>
                <td class="p-4 text-slate-900 dark:text-white">
                  {{ contact.phone_number }}
                </td>
                <td
                  v-if="activeTab === 'failed'"
                  class="p-4 text-slate-900 dark:text-white"
                >
                  {{ contact.error_message || 'Unknown Error' }}
                </td>
                <td class="p-4 text-slate-600 dark:text-white">
                  {{
                    contact.processed_at
                      ? new Date(contact.processed_at).toLocaleString()
                      : '-'
                  }}
                </td>
              </tr>
              <tr v-if="activeContacts.length === 0">
                <td
                  :colspan="activeTab === 'failed' ? '4' : '3'"
                  class="p-4 text-center text-slate-500 dark:text-white"
                >
                  {{
                    $t('CAMPAIGN.WHATSAPP.REPORT.NO_CONTACTS', {
                      type: activeTab,
                    })
                  }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <PaginationFooter
      class="mt-4"
      :current-page="currentPage"
      :total-items="activeContacts.length"
      :items-per-page="rowsPerPage"
      @update:current-page="onUpdatePage"
    />

    <!-- Pagination -->
    <!-- <div class="mt-4 flex items-center justify-between">
      <div class="text-sm text-slate-500 dark:text-white">
        Showing {{ activeContacts.length }} of
        {{
          activeTab === 'pending'
            ? totalProcessedCount + totalFailedCount
            : ['processed', 'read', 'delivered', 'replied'].includes(activeTab)
              ? totalProcessedCount
              : totalFailedCount
        }}
        contacts
      </div>
    </div> -->
  </div>
</template>

<style scoped>
.bg-dark-primary {
  background-color: #1b1c21;
}

.bg-n-solid-3 {
  background-color: #23242b;
}

.text-dark-primary {
  color: #ffffff;
}

.text-white {
  color: #ffffff;
}

.border-dark {
  border-color: #23242b;
}

.bg-dark-hover {
  background-color: #2d2e33;
}

.spinner {
  border: 4px solid #f3f3f3;
  border-top: 4px solid #3498db;
  border-radius: 50%;
  width: 40px;
  height: 40px;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

.metric-card {
  display: flex;
  flex-direction: row;
  background-color: #f8fafc;
  border-radius: 0.5rem;
  justify-content: space-between;
  padding: 12px;
}

.dark .metric-card {
  background-color: #2c2d36;
}
</style>
