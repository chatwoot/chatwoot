<template>
  <div class="column content-box">
    <!-- List Audit Logs -->
    <div class="row">
      <div class="small-8 columns with-right-space ">
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
            <tr v-for="auditLogItem in records" :key="auditLogItem.id">
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
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

export default {
  components: {
    TableFooter,
  },
  mixins: [alertMixin, timeMixin, globalConfigMixin],
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
      globalConfig: 'globalConfig/get',
    }),
  },
  mounted() {
    // Fetch API Call
    this.$store.dispatch('auditlogs/fetch', { page: 1 });
  },
  methods: {
    onPageChange(page) {
      window.history.pushState({}, null, `${this.$route.path}?page=${page}`);
      try {
        this.$store.dispatch('auditlogs/fetch', { page });
      } catch (error) {
        const errorMessage =
          error?.message ||
          this.$t('AUDIT_LOGS.API.ERROR_MESSAGE', {
            brandName: this.globalConfig.brandName,
          });
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
</style>
