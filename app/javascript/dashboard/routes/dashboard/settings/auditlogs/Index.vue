<template>
  <div class="column content-box">
    <!-- List Audit Logs -->
    <div class="row">
      <div class="small-8 columns with-right-space ">
        <p
          v-if="!uiFlags.fetchingList && !records.audit_logs.length"
          class="no-items-error-message"
        >
          {{ $t('AUDIT_LOGS.LIST.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.fetchingList"
          :message="$t('AUDIT_LOGS.LOADING')"
        />

        <table
          v-if="!uiFlags.fetchingList && records.audit_logs.length"
          class="woot-table"
        >
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
            <tr
              v-for="auditLogItem in records.audit_logs"
              :key="auditLogItem.id"
            >
              <td class="wrap-break-words">{{ auditLogItem.username }}</td>
              <td class="wrap-break-words">
                {{ auditLogItem.auditable_type }}.{{ auditLogItem.action }}
              </td>
              <td class="remote-address">
                {{ auditLogItem.remote_address }}
              </td>
              <td class="wrap-break-words">
                {{ dynamicTime(auditLogItem.created_at) }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    <table-footer
      :current-page="Number(records.current_page)"
      :total-count="records.total_entries"
      :page-size="15"
      @page-change="onPageChange"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import TableFooter from 'dashboard/components/widgets/TableFooter';
import timeMixin from 'dashboard/mixins/time';

export default {
  components: {
    TableFooter,
  },
  mixins: [timeMixin],
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
      records: 'getAuditLogs',
      uiFlags: 'getUIFlags',
    }),
  },
  mounted() {
    // Fetch API Call
    this.$store.dispatch('getAuditLog', { page: 1 });
  },
  methods: {
    showAlert(message) {
      // Reset loading, current selected agent
      this.loading[this.selectedResponse.id] = false;
      this.selectedResponse = {};
      // Show message
      this.auditLogsAPI.message = message;
      bus.$emit('newToastMessage', message);
    },
    onPageChange(page) {
      window.history.pushState({}, null, `${this.$route.path}?page=${page}`);
      this.$store.dispatch('getAuditLog', { page });
    },
  },
};
</script>
<style scoped>
.remote-address {
  width: 14rem;
}
.wrap-break-words {
  word-break: break-all;
  white-space: normal;
}
</style>
