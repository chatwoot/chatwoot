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
              <!-- Short Code  -->
              <td class="remote-address">
                {{ auditLogItem.remote_address }}
              </td>
              <!-- Content -->
              <!-- <td class="wrap-break-words">{{ dynamicTime(auditLogItem.created_at) }}</td> -->
              <td class="wrap-break-words">{{ auditLogItem.created_at }}</td>
              <td class="wrap-break-words">
                {{ auditLogItem.auditable_type }}.{{ auditLogItem.action }}
              </td>
              <td class="wrap-break-words">{{ auditLogItem.username }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';

export default {
  components: {},
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
    this.$store.dispatch('getAuditLog');
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
