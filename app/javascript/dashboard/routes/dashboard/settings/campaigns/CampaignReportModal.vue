<script>
import { defineComponent } from 'vue';
import { mapGetters } from 'vuex';

export default defineComponent({
  name: 'CampaignReportModal',
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
  },
  mounted() {
    this.$store
      .dispatch('campaigns/fetchCampaignContacts', this.campaign.display_id)
      .then(() => {
        this.fetchCampaignContacts();
      })
      .catch(error => {
        this.isLoading = false;
        this.error = error.message || this.$t('CAMPAIGN.REPORT.GENERIC_ERROR');
        this.$emit('error', error);
      });
  },
  methods: {
    fetchCampaignContacts() {
      this.isLoading = true;
      this.error = null;

      try {
        const contacts = this.contactDetails(this.campaign.display_id);

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
      } catch (error) {
        this.error = error.message || this.$t('CAMPAIGN.REPORT.GENERIC_ERROR');
        this.$emit('error', error);
      } finally {
        this.isLoading = false;
      }
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

    // exportContacts() {
    //   const contactsToExport = this.activeContacts;
    //   const csvData = contactsToExport.map(contact => {
    //     const baseData = {
    //       Name: contact.name,
    //       'Phone Number': contact.phone_number,
    //       Status: this.activeTab,
    //     };

    //     if (
    //       this.activeTab === 'processed' ||
    //       'read' ||
    //       'delivered' ||
    //       'replied' ||
    //       'pending'
    //     ) {
    //       baseData['Processed At'] = new Date(
    //         contact.processed_at
    //       ).toLocaleString();
    //     } else {
    //       baseData['Error Message'] = contact.error_message || 'Unknown Error';
    //     }

    //     return baseData;
    //   });

    //   const csv = Papa.unparse(csvData);
    //   const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    //   const link = document.createElement('a');
    //   const url = URL.createObjectURL(blob);
    //   link.setAttribute('href', url);
    //   link.setAttribute(
    //     'download',
    //     `${this.campaign.title}_${this.activeTab}_contacts.csv`
    //   );
    //   link.style.visibility = 'hidden';
    //   document.body.appendChild(link);
    //   link.click();
    //   document.body.removeChild(link);
    // },

    closeModal() {
      this.$emit('close');
    },
  },
});
</script>

<template>
  <div
    class="fixed inset-0 z-50 flex items-center justify-center dark:bg-black-900 dark:bg-opacity-40"
  >
    <div
      class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-60"
      @click.self="closeModal"
    >
      <div
        class="bg-white dark:bg-slate-800 rounded-lg shadow-xl w-11/12 max-w-4xl max-h-[90vh] flex flex-col"
      >
        <!-- Modal Header -->
        <div
          class="flex justify-between items-center p-6 border-b dark:border-slate-700"
        >
          <div class="flex flex-col">
            <h2
              class="text-xl font-semibold text-slate-900 dark:text-slate-100"
            >
              {{ $t('CAMPAIGN.REPORT.TITLE', { title: campaign.title }) }}
            </h2>
            <p class="text-sm text-slate-500">
              {{
                $t('CAMPAIGN.REPORT.CONTACTS_COUNT', { count: totalContacts })
              }}
            </p>
          </div>
        </div>

        <!-- Modal Content -->
        <div
          v-if="isLoading"
          class="flex-grow flex items-center justify-center p-6"
        >
          <div
            class="w-16 h-16 border-4 border-t-4 border-blue-600 border-solid rounded-full animate-spin"
          />
        </div>

        <div
          v-else-if="error"
          class="flex-grow flex items-center justify-center p-6"
        >
          <div class="text-red-500">{{ error }}</div>
        </div>

        <div v-else class="flex-grow overflow-auto p-6">
          <!-- Stats Grid -->
          <div class="grid grid-cols-4 gap-4 mb-8">
            <!-- Sent Messages -->
            <div class="bg-slate-50 dark:bg-slate-700 rounded-lg p-1">
              <div class="flex items-center justify-between">
                <span class="text-2xl font-bold text-blue-600 ml-4">{{
                  metrics.sent
                }}</span>
                <woot-button
                  icon="checkmark"
                  size="large"
                  color-scheme="primary"
                  class-names="button--only-icon mr-10 mt-3"
                />
              </div>
              <p class="text-s text-slate-600 dark:text-slate-300 ml-3">Sent</p>
            </div>

            <!-- Delivered Messages -->
            <div class="bg-slate-50 dark:bg-slate-700 rounded-lg p-1">
              <div class="flex items-center justify-between">
                <span class="text-2xl font-bold text-blue-600 ml-4">{{
                  metrics.delivered
                }}</span>
                <woot-button
                  icon="checkmark-double"
                  size="large"
                  color-scheme="primary"
                  class-names="button--only-icon mr-10 mt-3"
                />
              </div>
              <p class="text-s text-slate-600 dark:text-slate-300 ml-2">
                Delivered
              </p>
            </div>

            <!-- Read Messages -->
            <div class="bg-slate-50 dark:bg-slate-700 rounded-lg p-1">
              <div class="flex items-center justify-between">
                <span class="text-2xl font-bold text-blue-600 ml-6">{{
                  metrics.read
                }}</span>
                <woot-button
                  icon="eye-show"
                  size="large"
                  color-scheme="primary"
                  class-names="button--only-icon mr-10 mt-3"
                />
              </div>
              <p class="text-s text-slate-600 dark:text-slate-300 ml-3">Read</p>
            </div>

            <!-- Replied Messages -->
            <div class="bg-slate-50 dark:bg-slate-700 rounded-lg p-1">
              <div class="flex items-center justify-between">
                <span class="text-2xl font-bold text-blue-600 ml-6">{{
                  metrics.replied
                }}</span>
                <woot-button
                  icon="arrow-reply"
                  size="large"
                  color-scheme="primary"
                  class-names="button--only-icon mr-10 mt-3"
                />
              </div>
              <p class="text-s text-slate-600 dark:text-slate-300 ml-3">
                Replied
              </p>
            </div>

            <!-- Failed Messages -->
            <div class="bg-slate-50 dark:bg-slate-700 rounded-lg p-1">
              <div class="flex items-center justify-between">
                <span class="text-2xl font-bold text-blue-600 ml-4">{{
                  metrics.failed
                }}</span>
                <woot-button
                  icon="error-circle"
                  size="large"
                  color-scheme="primary"
                  class-names="button--only-icon mr-10 mt-3"
                />
              </div>
              <p class="text-s text-slate-600 dark:text-slate-300 ml-3">
                Failed
              </p>
            </div>

            <!-- Processing Messages -->
            <div class="bg-slate-50 dark:bg-slate-700 rounded-lg p-1">
              <div class="flex items-center justify-between">
                <span class="text-2xl font-bold text-blue-600 ml-5">{{
                  metrics.processing
                }}</span>
                <woot-button
                  icon="repeat"
                  size="large"
                  color-scheme="primary"
                  class-names="button--only-icon mr-10 mt-3"
                />
              </div>
              <p class="text-s text-slate-600 dark:text-slate-300 ml-2">
                Processing
              </p>
            </div>
          </div>

          <!-- Controls -->
          <div class="flex justify-between items-center mb-2">
            <div class="flex items-center space-x-4">
              <input
                v-model="searchQuery"
                type="text"
                :placeholder="$t('CAMPAIGN.REPORT.SEARCH_PLACEHOLDER')"
                class="px-4 w-96 py-2 border rounded-lg dark:bg-slate-700 dark:border-slate-600"
              />
            </div>
            <div class="flex space-x-2 overflow-x-auto">
              <select v-model="activeTab">
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
          <div class="overflow-x-auto bg-white dark:bg-slate-700 rounded-lg">
            <div class="max-h-[500px] overflow-y-auto">
              <table class="w-full">
                <thead class="sticky top-0 bg-white dark:bg-slate-700 z-10">
                  <tr class="border-b dark:border-slate-400">
                    <th
                      class="p-4 text-left font-medium text-slate-700 dark:text-slate-200"
                    >
                      <div
                        class="flex items-center cursor-pointer"
                        @click="sortContacts('name')"
                      >
                        Contact
                        <i
                          v-if="sortConfig.key === 'name'"
                          :class="sortConfig.direction === 'asc' ? '▲' : '▼'"
                          class="ml-1"
                        />
                      </div>
                    </th>
                    <th
                      class="p-4 text-left font-medium text-slate-700 dark:text-slate-200"
                    >
                      <div
                        class="flex items-center cursor-pointer"
                        @click="sortContacts('phone_number')"
                      >
                        Phone
                        <i
                          v-if="sortConfig.key === 'phone_number'"
                          :class="sortConfig.direction === 'asc' ? '▲' : '▼'"
                          class="ml-1"
                        />
                      </div>
                    </th>
                    <th
                      v-if="activeTab === 'failed'"
                      class="p-4 text-left font-medium text-slate-700 dark:text-slate-200"
                    >
                      <div class="flex items-center">Reason</div>
                    </th>
                    <th
                      class="p-4 text-left font-medium text-slate-700 dark:text-slate-200"
                    >
                      <div
                        class="flex items-center cursor-pointer"
                        @click="sortContacts('processed_at')"
                      >
                        Time
                        <i
                          v-if="sortConfig.key === 'processed_at'"
                          :class="sortConfig.direction === 'asc' ? '▲' : '▼'"
                          class="ml-1"
                        />
                      </div>
                    </th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    v-for="contact in activeContacts"
                    :key="contact.id"
                    class="border-b last:border-b-0 dark:border-slate-600 hover:bg-slate-50 dark:hover:bg-slate-600"
                  >
                    <td class="p-4 text-slate-900 dark:text-slate-200">
                      {{ contact.name }}
                    </td>
                    <td class="p-4 text-slate-900 dark:text-slate-200">
                      {{ contact.phone_number }}
                    </td>
                    <td
                      v-if="activeTab === 'failed'"
                      class="p-4 text-slate-900 dark:text-slate-200"
                    >
                      {{ contact.error_message || 'Unknown Error' }}
                    </td>
                    <td class="p-4 text-slate-600 dark:text-slate-300">
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
                      class="p-4 text-center text-slate-500 dark:text-slate-400"
                    >
                      {{
                        $t('CAMPAIGN.REPORT.NO_CONTACTS', { type: activeTab })
                      }}
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>

          <!-- Pagination -->
          <div class="mt-4 flex items-center justify-between">
            <div class="text-sm text-slate-500 dark:text-slate-400">
              Showing {{ activeContacts.length }} of
              {{
                activeTab === 'pending'
                  ? totalProcessedCount + totalFailedCount
                  : ['processed', 'read', 'delivered', 'replied'].includes(
                      activeTab
                    )
                  ? totalProcessedCount
                  : totalFailedCount
              }}
              contacts
            </div>
          </div>
        </div>

        <!-- Modal Footer -->
        <div
          class="p-6 border-t dark:border-slate-700 flex justify-between items-center"
        >
          <woot-button
            varaint="clear"
            color-scheme="success"
            class-names="clear flex items-center"
            icon="download"
            @click="exportContacts"
          >
            {{ $t('CAMPAIGN.REPORT.EXPORT_CSV') }}
          </woot-button>

          <button
            class="px-4 py-2 border border-slate-300 rounded-lg text-slate-700 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-700 transition-colors"
            @click="closeModal"
          >
            {{ $t('CAMPAIGN.REPORT.CLOSE') }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
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
</style>
