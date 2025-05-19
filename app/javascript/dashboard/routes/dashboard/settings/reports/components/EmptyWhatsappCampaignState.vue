<script>
import EmptyStateLayout from 'dashboard/components-next/EmptyStateLayout.vue';
import { defineComponent } from 'vue';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';

export default defineComponent({
  name: 'EmptyCampaignReportModal',
  components: { EmptyStateLayout },
  data() {
    return {
      processedContacts: [],
      failedContacts: [],
      readContacts: [],
      deliveredContacts: [],
      repliedContacts: [],
      pendingContacts: [],
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
  methods: {
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
});
</script>

<template>
  <EmptyStateLayout
    :title="$t('WHATSAPP_REPORTS.EMPTY_TITLE')"
    :subtitle="$t('WHATSAPP_REPORTS.EMPTY_SUBTITLE')"
  >
    <template #empty-state-item>
      <!-- Modal Header -->
      <div
        class="flex-col lg:flex-row flex flex-wrap mx-0 shadow outline-1 outline outline-n-container rounded-xl bg-n-solid-2 px-6 py-8 gap-16 mt-6"
      >
        <p class="text-slate-500 dark:text-white text-lg">
          {{ $t('WHATSAPP_REPORTS.REPORT_TITLE', { title: '--' }) }}
        </p>
        <p class="text-lg text-slate-500 dark:text-white">
          {{
            $t('WHATSAPP_REPORTS.CONTACTS_COUNT', {
              count: '--',
            })
          }}
        </p>
      </div>

      <div class="flex-grow overflow-auto p-6">
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
        <div class="overflow-x-auto bg-white dark:bg-n-solid-3 rounded-lg">
          <div class="max-h-[500px] overflow-y-auto">
            <table class="w-full">
              <thead class="sticky top-0 bg-white dark:bg-n-solid-3 z-10">
                <tr class="border-b dark:border-dark">
                  <th
                    class="p-4 text-left font-medium text-slate-700 dark:text-white"
                  >
                    <div class="flex items-center cursor-pointer">
                      Contact
                      <i
                        v-if="sortConfig.key === 'name'"
                        :class="sortConfig.direction === 'asc' ? '▲' : '▼'"
                        class="ml-1"
                      />
                    </div>
                  </th>
                  <th
                    class="p-4 text-left font-medium text-slate-700 dark:text-white"
                  >
                    <div class="flex items-center cursor-pointer">
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
                    class="p-4 text-left font-medium text-slate-700 dark:text-white"
                  >
                    <div class="flex items-center">Reason</div>
                  </th>
                  <th
                    class="p-4 text-left font-medium text-slate-700 dark:text-white"
                  >
                    <div class="flex items-center cursor-pointer">
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
  </EmptyStateLayout>
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
