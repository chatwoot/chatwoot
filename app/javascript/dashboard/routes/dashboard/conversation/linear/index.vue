<template>
  <div class="flex flex-col">
    <div class="flex flex-row gap-2">
      <woot-button
        v-if="shouldShowAddButton"
        variant="smooth"
        icon="add"
        size="tiny"
        @click="showCreateIssuePopup"
      >
        {{ $t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK_BUTTON') }}
      </woot-button>
    </div>
    <div v-if="isFetching" class="flex items-center justify-center">
      <span class="text-sm font-medium text-slate-800 dark:text-slate-100">
        {{ $t('INTEGRATION_SETTINGS.LINEAR.LOADING') }}
      </span>
    </div>

    <div v-if="shouldShowItem" class="flex flex-col gap-2">
      <issue-item
        :issue="linkedIssue.issue"
        :link-id="linkedIssue.id"
        :conversation-id="conversationId"
        @unlink-issue="unlinkIssue"
      />
    </div>
    <woot-modal
      :show.sync="showPopup"
      :on-close="closePopup"
      class="!items-start [&>div]:!top-12"
    >
      <create-or-link-issue
        :conversation-id="conversationId"
        :account-id="currentAccountId"
        @close="closePopup"
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
      isFetching: false,
      showPopup: false,
      linkedIssue: null,
    };
  },
  computed: {
    ...mapGetters({
      currentAccountId: 'getCurrentAccountId',
    }),
    shouldShowAddButton() {
      return !this.isFetching && !this.linkedIssue;
    },
    shouldShowItem() {
      return !this.isFetching && this.linkedIssue;
    },
  },
  watch: {
    conversationId(newConversationId, prevConversationId) {
      if (newConversationId && newConversationId !== prevConversationId) {
        this.loadLinkedIssue();
      }
    },
  },
  mounted() {
    this.loadLinkedIssue();
  },
  methods: {
    showCreateIssuePopup() {
      this.showPopup = true;
    },
    closePopup() {
      this.showPopup = false;
      this.loadLinkedIssue();
    },
    async loadLinkedIssue() {
      try {
        this.isFetching = true;
        const response = await LinearAPI.getLinkedIssue(this.conversationId);
        const issues = response.data;
        this.linkedIssue = issues && issues.length ? issues[0] : null;
      } catch (error) {
        this.showAlert(this.$t('INTEGRATION_SETTINGS.LINEAR.LOADING_ERROR'));
      } finally {
        this.isFetching = false;
      }
    },
    async unlinkIssue(linkId) {
      try {
        await LinearAPI.unlinkIssue(linkId);
        this.linkedIssue = null;
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
