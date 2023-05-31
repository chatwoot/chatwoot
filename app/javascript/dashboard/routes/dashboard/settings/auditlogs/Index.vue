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
    this.$store.dispatch('auditlogs/fetch', { page: 1 });
    this.$store.dispatch('agents/get');
  },
  methods: {
    getAgentName(email) {
      if (email === null) {
        return this.$t('AUDIT_LOGS.DEFAULT_USER');
      }
      const agentName = this.agentList.find(agent => agent.email === email)
        ?.name;
      // If agent does not exist(removed/deleted), return email from audit log
      return agentName || email;
    },
    generateLogText(auditLogItem) {
      const username = this.getAgentName(auditLogItem.username);
      const auditableType = auditLogItem.auditable_type.toLowerCase();
      const action = auditLogItem.action.toLowerCase();
      const auditId = auditLogItem.auditable_id;

      const startsWithVowel = /^[aeiou]/i.test(auditableType);
      const articleKey = startsWithVowel ? 'ACTION_VOWEL' : 'ACTION_CONSONANT';
      const logActions = {
        create: this.$t(`AUDIT_LOGS.${articleKey}.ADD`),
        destroy: this.$t(`AUDIT_LOGS.${articleKey}.DELETE`),
        update: this.$t(`AUDIT_LOGS.${articleKey}.EDIT`),
        sign_in: this.$t(`AUDIT_LOGS.${articleKey}.SIGN_IN`),
        sign_out: this.$t(`AUDIT_LOGS.${articleKey}.SIGN_OUT`),
      };

      // detect if the action is a custom user action, which involves
      // only the user, such as signing in, signing out etc.
      // if it is, then do not show the auditable type
      const userActions = this.isUserAction(action);

      return `${username} ${logActions[action] || action} ${
        userActions ? '' : `${auditableType} (#${auditId})`
      }`;
    },
    isUserAction(action) {
      return ['sign_in', 'sign_out'].includes(action);
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
