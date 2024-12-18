<script>
import { defineComponent } from 'vue';
import { mapGetters } from 'vuex';
import Papa from 'papaparse';

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
      isLoading: true,
      error: null,

      // New search and filter features
      searchQuery: '',
      activeTab: 'processed', // 'processed' or 'failed'
      sortConfig: {
        key: null,
        direction: 'asc',
      },
    };
  },
  computed: {
    ...mapGetters({
      contactDetails: 'campaigns/getContactsForCampaign',
      uiFlags: 'campaigns/getUIFlags',
    }),

    // Filtered and searched contacts
    filteredProcessedContacts() {
      return this.filterAndSearchContacts(this.processedContacts);
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

    // Computed property to show active tab contacts
    activeContacts() {
      return this.activeTab === 'processed'
        ? this.filteredProcessedContacts
        : this.filteredFailedContacts;
    },
  },
  mounted() {
    this.$store
      .dispatch('campaigns/fetchCampaignContacts', this.campaign.id)
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
      // Reset state before fetching
      this.isLoading = true;
      this.error = null;
      this.processedContacts = [];
      this.failedContacts = [];

      try {
        // Retrieve contacts using the getter with campaign ID
        const contacts = this.contactDetails(this.campaign.id);
        // Ensure contacts is an array
        this.processedContacts = contacts.processed_contacts || [];
        this.failedContacts = contacts.failed_contacts || [];
      } catch (error) {
        // Comprehensive error handling
        console.error('Failed to retrieve campaign contacts:', error);
        this.error = error.message || this.$t('CAMPAIGN.REPORT.GENERIC_ERROR');
        this.$emit('error', error);
      } finally {
        // Ensure loading state is updated
        this.isLoading = false;
      }
    },

    // New method for filtering and searching contacts
    filterAndSearchContacts(contacts) {
      if (!contacts) return [];

      // Convert search query to lowercase for case-insensitive search
      const query = this.searchQuery.toLowerCase();

      return contacts.filter(
        contact =>
          contact.name.toLowerCase().includes(query) ||
          contact.phone_number.toLowerCase().includes(query)
      );
    },

    // Method to sort contacts
    sortContacts(key) {
      // Toggle sort direction if same key is clicked
      if (this.sortConfig.key === key) {
        this.sortConfig.direction =
          this.sortConfig.direction === 'asc' ? 'desc' : 'asc';
      } else {
        this.sortConfig.key = key;
        this.sortConfig.direction = 'asc';
      }

      // Perform sorting
      const multiplier = this.sortConfig.direction === 'asc' ? 1 : -1;

      if (this.activeTab === 'processed') {
        this.processedContacts.sort((a, b) => {
          if (a[key] < b[key]) return -1 * multiplier;
          if (a[key] > b[key]) return 1 * multiplier;
          return 0;
        });
      } else {
        this.failedContacts.sort((a, b) => {
          if (a[key] < b[key]) return -1 * multiplier;
          if (a[key] > b[key]) return 1 * multiplier;
          return 0;
        });
      }
    },

    // Method to export contacts to CSV
    exportContacts() {
      const contactsToExport =
        this.activeTab === 'processed'
          ? this.processedContacts
          : this.failedContacts;

      // Prepare CSV data
      const csvData = contactsToExport.map(contact => {
        const baseData = {
          Name: contact.name,
          'Phone Number': contact.phone_number,
        };

        // Conditionally add additional field based on active tab
        if (this.activeTab === 'processed') {
          baseData['Processed At'] = new Date(
            contact.processed_at
          ).toLocaleString();
        } else {
          baseData['Error Message'] = contact.error_message || 'Unknown Error';
        }

        return baseData;
      });

      // Generate CSV
      const csv = Papa.unparse(csvData);

      // Create download
      const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
      const link = document.createElement('a');
      const url = URL.createObjectURL(blob);
      link.setAttribute('href', url);
      link.setAttribute(
        'download',
        `${this.campaign.title}_${this.activeTab}_contacts.csv`
      );
      link.style.visibility = 'hidden';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    },

    closeModal() {
      // Emit close event to parent component
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
          <h2 class="text-xl font-semibold text-slate-900 dark:text-slate-100">
            {{ $t('CAMPAIGN.REPORT.TITLE', { title: campaign.title }) }}
          </h2>
          <button
            @click="closeModal"
            class="text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200"
          >
            <i class="ri-close-line text-2xl"></i>
          </button>
        </div>

        <!-- Modal Content -->
        <div
          v-if="isLoading"
          class="flex-grow flex items-center justify-center p-6"
        >
          <div class="spinner"></div>
        </div>

        <div
          v-else-if="error"
          class="flex-grow flex items-center justify-center p-6"
        >
          <div class="text-red-500">
            {{ error }}
          </div>
        </div>

        <div v-else class="flex-grow overflow-auto p-6">
          <!-- Search and Filter Section -->
          <div class="mb-6 flex justify-between items-center">
            <div class="flex space-x-4 items-center">
              <!-- Search Input -->
              <input
                v-model="searchQuery"
                :placeholder="$t('CAMPAIGN.REPORT.SEARCH_PLACEHOLDER')"
                class="border rounded-md px-3 py-2 w-64 dark:bg-black-900 dark:border-slate-600"
              />
            </div>
            <div class="flex space-x-4">
              <!-- Tab Selector -->
              <button
                @click="activeTab = 'processed'"
                :class="{
                  'bg-green-100 text-green-700': activeTab === 'processed',
                  'bg-slate-400 text-slate-700': activeTab !== 'processed',
                }"
                class="px-4 py-2 rounded-md transition-colors"
              >
                {{ $t('CAMPAIGN.REPORT.PROCESSED_CONTACTS') }} ({{
                  totalProcessedCount
                }})
              </button>
              <button
                @click="activeTab = 'failed'"
                :class="{
                  'bg-red-100 text-red-700': activeTab === 'failed',
                  'bg-slate-400 text-slate-700': activeTab !== 'failed',
                }"
                class="px-4 py-2 rounded-md transition-colors"
              >
                {{ $t('CAMPAIGN.REPORT.FAILED_CONTACTS') }} ({{
                  totalFailedCount
                }})
              </button>
            </div>
          </div>

          <!-- Contacts Table -->
          <div class="overflow-x-auto">
            <table class="w-full">
              <thead>
                <tr class="bg-slate-100 dark:bg-black-900">
                  <th
                    @click="sortContacts('name')"
                    class="p-3 text-left cursor-pointer hover:bg-slate-200 dark:hover:bg-black-800"
                  >
                    Name
                    <span v-if="sortConfig.key === 'name'">
                      {{ sortConfig.direction === 'asc' ? '▲' : '▼' }}
                    </span>
                  </th>
                  <th
                    @click="sortContacts('phone_number')"
                    class="p-3 text-left cursor-pointer hover:bg-slate-200 dark:hover:bg-black-800"
                  >
                    Phone Number
                    <span v-if="sortConfig.key === 'phone_number'">
                      {{ sortConfig.direction === 'asc' ? '▲' : '▼' }}
                    </span>
                  </th>
                  <th class="p-3 text-left">
                    {{
                      activeTab === 'processed'
                        ? 'Processed At'
                        : 'Error Message'
                    }}
                  </th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="contact in activeContacts"
                  :key="contact.id"
                  :class="
                    activeTab === 'processed'
                      ? 'bg-green-50 dark:bg-slate-700'
                      : 'bg-red-50 dark:bg-slate-700'
                  "
                  class="border-b last:border-b-0"
                >
                  <td class="p-3">{{ contact.name }}</td>
                  <td class="p-3">{{ contact.phone_number }}</td>
                  <td class="p-3">
                    {{
                      activeTab === 'processed'
                        ? new Date(contact.processed_at).toLocaleString()
                        : contact.error_message ||
                          $t('CAMPAIGN.REPORT.UNKNOWN_ERROR')
                    }}
                  </td>
                </tr>
              </tbody>
            </table>

            <!-- No Contacts Message -->
            <p
              v-if="activeContacts.length === 0"
              class="text-center text-slate-400 p-6"
            >
              {{
                activeTab === 'processed'
                  ? $t('CAMPAIGN.REPORT.NO_PROCESSED_CONTACTS')
                  : $t('CAMPAIGN.REPORT.NO_FAILED_CONTACTS')
              }}
            </p>
          </div>
        </div>

        <!-- Modal Footer -->
        <div
          class="p-6 border-t dark:border-slate-700 flex justify-between items-center"
        >
          <button
            @click="exportContacts"
            class="bg-blue-500 text-white px-4 py-2 rounded-md hover:bg-blue-600 transition-colors"
          >
            {{ $t('CAMPAIGN.REPORT.EXPORT_CSV') }}
          </button>
          <woot-button @click="closeModal" variant="secondary">
            {{ $t('CAMPAIGN.REPORT.CLOSE') }}
          </woot-button>
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
