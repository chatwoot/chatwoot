<template>
  <div class="column content-box audit-log--settings">
    <!-- List Audit Logs -->
    <div>
      <div>
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
          class="woot-table width-100"
        >
          <colgroup>
            <col class="column-activity" />
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
  beforeRouteEnter(to, from, next) {
    // Fetch Audit Logs on page load without manual refresh
    next(vm => {
      vm.fetchAuditLogs();
    });
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
    fetchAuditLogs() {
      const page = this.$route.query.page ?? 1;
      this.$store.dispatch('auditlogs/fetch', { page }).catch(error => {
        const errorMessage =
          error?.message || this.$t('AUDIT_LOGS.API.ERROR_MESSAGE');
        this.showAlert(errorMessage);
      });
    },
    getAgentName(user_id) {
      if (user_id === null) {
        return this.$t('AUDIT_LOGS.DEFAULT_USER');
      }
      const agentName = this.agentList.find(agent => agent.id === user_id)
        ?.name;
      // If agent does not exist(removed/deleted), return email from audit log
      return agentName || user_id;
    },
    extractChangedAccountUserValues(audited_changes) {
      let changes = [];
      let values = [];
      const roleMapping = {
        0: 'agent',
        1: 'admin',
      };

      const availabilityMapping = {
        0: 'online',
        1: 'offline',
        2: 'busy',
      };

      // Iterate over roles
      if (audited_changes.role && audited_changes.role.length) {
        changes.push('role');
        values.push(
          roleMapping[audited_changes.role[audited_changes.role.length - 1]]
        );
      }

      // Iterate over availability
      if (audited_changes.availability && audited_changes.availability.length) {
        changes.push('availability');
        values.push(
          availabilityMapping[
            audited_changes.availability[
              audited_changes.availability.length - 1
            ]
          ]
        );
      }

      return { changes, values };
    },
    generateLogText(auditLogItem) {
      const agentName = this.getAgentName(auditLogItem.user_id);
      const auditableType = auditLogItem.auditable_type.toLowerCase();
      const action = auditLogItem.action.toLowerCase();
      const auditId = auditLogItem.auditable_id;
      let logActionKey = `${auditableType}:${action}`;

      const translationPayload = {
        agentName,
        id: auditId,
      };

      if (auditableType === 'accountuser') {
        if (action === 'update') {
          if (auditLogItem.user_id === auditLogItem.auditable.user_id) {
            logActionKey += ':self';
          } else {
            logActionKey += ':other';
            translationPayload.user = this.getAgentName(
              auditLogItem.auditable.user_id
            );
          }
          translationPayload.invitee = this.getAgentName(
            auditLogItem.auditable.user_id
          );

          const accountUserChanges = this.extractChangedAccountUserValues(
            auditLogItem.audited_changes
          );
          translationPayload.attributes = accountUserChanges.changes;
          translationPayload.values = accountUserChanges.values;
        }

        if (action === 'create') {
          translationPayload.invitee = this.getAgentName(
            auditLogItem.audited_changes.user_id
          );
          if (auditLogItem.audited_changes.role === 0) {
            translationPayload.role = 'admin';
          } else {
            translationPayload.role = 'agent';
          }
        }
      }

      const translationKeys = {
        'automationrule:create': `AUDIT_LOGS.AUTOMATION_RULE.ADD`,
        'automationrule:update': `AUDIT_LOGS.AUTOMATION_RULE.EDIT`,
        'automationrule:destroy': `AUDIT_LOGS.AUTOMATION_RULE.DELETE`,
        'webhook:create': `AUDIT_LOGS.WEBHOOK.ADD`,
        'webhook:update': `AUDIT_LOGS.WEBHOOK.EDIT`,
        'webhook:destroy': `AUDIT_LOGS.WEBHOOK.DELETE`,
        'inbox:create': `AUDIT_LOGS.INBOX.ADD`,
        'inbox:update': `AUDIT_LOGS.INBOX.EDIT`,
        'inbox:destroy': `AUDIT_LOGS.INBOX.DELETE`,
        'user:sign_in': `AUDIT_LOGS.USER_ACTION.SIGN_IN`,
        'user:sign_out': `AUDIT_LOGS.USER_ACTION.SIGN_OUT`,
        'team:create': `AUDIT_LOGS.TEAM.ADD`,
        'team:update': `AUDIT_LOGS.TEAM.EDIT`,
        'team:destroy': `AUDIT_LOGS.TEAM.DELETE`,
        'macro:create': `AUDIT_LOGS.MACRO.ADD`,
        'macro:update': `AUDIT_LOGS.MACRO.EDIT`,
        'macro:destroy': `AUDIT_LOGS.MACRO.DELETE`,
        'accountuser:create': `AUDIT_LOGS.ACCOUNT_USER.ADD`,
        'accountuser:update:self': `AUDIT_LOGS.ACCOUNT_USER.EDIT.SELF`,
        'accountuser:update:other': `AUDIT_LOGS.ACCOUNT_USER.EDIT.OTHER`,
      };

      return this.$t(translationKeys[logActionKey] || '', translationPayload);
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

<style lang="scss" scoped>
.audit-log--settings {
  display: flex;
  justify-content: space-between;
  flex-direction: column;

  .remote-address {
    width: 14rem;
  }

  .wrap-break-words {
    word-break: break-all;
    white-space: normal;
  }

  .column-activity {
    width: 60%;
  }
}
</style>
