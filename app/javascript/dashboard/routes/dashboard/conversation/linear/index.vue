<template>
  <div class="flex flex-col">
    <div class="flex flex-row gap-2">
      <woot-button
        v-if="!isLoading && !issues.length"
        variant="smooth"
        icon="add"
        size="tiny"
        @click="showCreateIssuePopup"
      >
        {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK_BUTTON') }}
      </woot-button>
    </div>
    <div v-if="isLoading" class="flex items-center justify-center">
      <span class="text-sm font-medium text-slate-800 dark:text-slate-100">
        {{ $t('INTEGRATION_SETTINGS.LINEAR.LOADING') }}
      </span>
    </div>

    <div v-if="!isLoading && issues.length" class="flex flex-col gap-2">
      <issue-item
        v-for="issue in issues"
        :key="issue.issue.id"
        :issue="issue.issue"
        :link-id="issue.id"
        :conversation-id="conversationId"
        @unlink-issue="unlinkIssue"
      />
    </div>
    <woot-modal
      :show.sync="showAddPopup"
      :on-close="hideAddPopup"
      class="!items-start [&>div]:!top-12"
    >
      <create-or-link-issue
        :conversation-id="conversationId"
        :account-id="currentAccountId"
        @close="hideAddPopup"
      />
    </woot-modal>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import IssueItem from './IssueItem.vue';
import accountMixin from 'dashboard/mixins/account.js';
import alertMixin from 'shared/mixins/alertMixin';
import CreateOrLinkIssue from './CreateOrLinkIssue.vue';
import LinearAPI from 'dashboard/api/integrations/linear';

export default {
  components: {
    IssueItem,
    CreateOrLinkIssue,
  },
  mixins: [accountMixin, alertMixin],
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      showAddPopup: false,
      issues: [],
    };
  },
  computed: {
    ...mapGetters({
      currentAccountId: 'getCurrentAccountId',
    }),
  },
  mounted() {
    this.loadIssues();
  },
  methods: {
    showCreateIssuePopup() {
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
      this.loadIssues();
    },
    async loadIssues() {
      try {
        this.isLoading = true;
        const response = await LinearAPI.getLinkedIssue(this.conversationId);
        this.issues = response.data;
      } catch (error) {
        this.showAlert(
          this.$t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK.LOADING_ERROR')
        );
      } finally {
        this.isLoading = false;
      }
    },
    async unlinkIssue(linkId) {
      try {
        await LinearAPI.unlinkIssue(linkId);
        this.issues = [];
        this.showAlert(this.$t('INTEGRATION_SETTINGS.LINEAR.UNLINK.SUCCESS'));
      } catch (error) {
        this.showAlert(
          this.$t('INTEGRATION_SETTINGS.LINEAR.UNLINK.DELETE_ERROR')
        );
      }
    },
  },
};
</script>
