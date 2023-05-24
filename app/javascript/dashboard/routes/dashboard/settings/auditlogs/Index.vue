<template>
  <div class="column content-box">
    <!-- List Audit Logs -->
    <div class="">
      <div class="">
        <p
          v-if="!uiFlags.fetchingList && !records.length"
          class="no-items-error-message"
        >
          {{ $t('AUDIT_LOGS.LIST.404') }}
        </p>
        <woot-loading-state
          v-if="uiFlags.fetchingList"
          :message="$t('AUDIT_LOGS.LOADING')"
        />

        <table
          v-if="!uiFlags.fetchingList && records.length"
          class="woot-table full-width-table"
        >
          <colgroup>
            <col style="width: 60%" />
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
              <td class="wrap-break-words">
                {{ generateLogText(auditLogItem) }}
              </td>
              <td class="wrap-break-words">
                {{
                  messageTimestamp(
                    auditLogItem.created_at,
                    'MMM dd, yyyy hh:mm a'
                  )
                }}
              </td>
              <td class="remote-address">
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
      @page-change="onPageChange"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import TableFooter from 'dashboard/components/widgets/TableFooter';
import timeMixin from 'dashboard/mixins/time';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  components: {
    TableFooter,
  },
  mixins: [alertMixin, timeMixin],
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
    }),
  },
  mounted() {
    // Fetch API Call
    this.$store.dispatch('auditlogs/fetch', { page: 1 });
  },
  methods: {
    generateLogText(auditLogItem) {
      const username =
        auditLogItem.username !== null
          ? auditLogItem.username
          : this.$t('AUDIT_LOGS.ACTION.SYSTEM');
      const auditableType = auditLogItem.auditable_type.toLowerCase();
      const action = auditLogItem.action.toLowerCase();

      if (auditLogItem.action === 'create') {
        return `${username} ${this.$t(
          'AUDIT_LOGS.ACTION.ADD'
        )} ${auditableType}`;
      }
      if (auditLogItem.action === 'destroy') {
        return `${username} ${this.$t(
          'AUDIT_LOGS.ACTION.DELETE'
        )} ${auditableType}`;
      }
      if (auditLogItem.action === 'update') {
        return `${username} ${this.$t(
          'AUDIT_LOGS.ACTION.EDIT'
        )} ${auditableType}`;
      }
      if (auditLogItem.action === 'sign_in') {
        return `${username} ${this.$t('AUDIT_LOGS.ACTION.SIGN_IN')}`;
      }
      return `${username} did ${action} on ${auditableType}`;
    },
    onPageChange(page) {
      window.history.pushState({}, null, `${this.$route.path}?page=${page}`);
      try {
        this.$store.dispatch('auditlogs/fetch', { page });
      } catch (error) {
        const errorMessage =
          error?.message || this.$t('AUDIT_LOGS.API.ERROR_MESSAGE');
        this.showAlert(errorMessage);
      }
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
.full-width-table {
  width: 100%;
}

.column-activity {
  width: 60%;
}
</style>
