<template>
  <div class="flex flex-col justify-between flex-1 p-4 overflow-auto">
    <!-- List Audit Logs -->
    <div>
      <div>
        <p
          v-if="!uiFlags.fetchingList && !records.length"
          class="flex flex-col items-center justify-center h-full"
        >
          {{ $t('AUDIT_LOGS.LIST.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.fetchingList"
          :message="$t('AUDIT_LOGS.LOADING')"
        />

        <table
          v-if="!uiFlags.fetchingList && records.length"
          class="w-full woot-table"
        >
          <colgroup>
            <col class="w-3/5" />
            <col />
            <col />
          </colgroup>
          <thead>
            <!-- Header -->
            <th
              v-for="thHeader in $t('AUDIT_LOGS.LIST.TABLE_HEADER')"
              :key="thHeader"
            >
              {{ thHeader }}
            </th>
          </thead>
          <tbody>
            <tr v-for="auditLogItem in records" :key="auditLogItem.id">
              <td class="break-all whitespace-nowrap">
                {{ generateLogText(auditLogItem) }}
              </td>
              <td class="break-all whitespace-nowrap">
                {{
                  messageTimestamp(
                    auditLogItem.created_at,
                    'MMM dd, yyyy hh:mm a'
                  )
                }}
              </td>
              <td class="w-[8.75rem]">
                {{ auditLogItem.remote_address }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    <table-footer
      :current-page="Number(meta.currentPage)"
      :total-count="meta.totalEntries"
      :page-size="meta.perPage"
      class="!bg-slate-25 dark:!bg-slate-900 border-t border-slate-75 dark:border-slate-700/50"
      @page-change="onPageChange"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import TableFooter from 'dashboard/components/widgets/TableFooter.vue';
import {
  generateTranslationPayload,
  generateLogActionKey,
} from 'dashboard/helper/auditlogHelper';

export default {
  components: {
    TableFooter,
  },
  beforeRouteEnter(to, from, next) {
    // Fetch Audit Logs on page load without manual refresh
    next(vm => {
      vm.fetchAuditLogs();
    });
  },
  data() {
    return {
      loading: {},
      auditLogsAPI: {
        message: '',
      },
    };
  },
  computed: {
    ...mapGetters({
      records: 'auditlogs/getAuditLogs',
      uiFlags: 'auditlogs/getUIFlags',
      meta: 'auditlogs/getMeta',
      agentList: 'agents/getAgents',
    }),
  },
  mounted() {
    // Fetch API Call
    this.$store.dispatch('agents/get');
  },
  methods: {
    messageTimestamp,
    fetchAuditLogs() {
      const page = this.$route.query.page ?? 1;
      this.$store.dispatch('auditlogs/fetch', { page }).catch(error => {
        const errorMessage =
          error?.message || this.$t('AUDIT_LOGS.API.ERROR_MESSAGE');
        useAlert(errorMessage);
      });
    },
    generateLogText(auditLogItem) {
      const translationPayload = generateTranslationPayload(
        auditLogItem,
        this.agentList
      );
      const translationKey = generateLogActionKey(auditLogItem);

      return this.$t(translationKey, translationPayload);
    },
    onPageChange(page) {
      window.history.pushState({}, null, `${this.$route.path}?page=${page}`);
      try {
        this.$store.dispatch('auditlogs/fetch', { page });
      } catch (error) {
        const errorMessage =
          error?.message || this.$t('AUDIT_LOGS.API.ERROR_MESSAGE');
        useAlert(errorMessage);
      }
    },
  },
};
</script>
