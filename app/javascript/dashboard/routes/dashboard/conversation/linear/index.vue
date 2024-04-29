<template>
  <div class="flex flex-col">
    <div class="flex flex-row gap-2">
      <woot-button
        v-if="!isLoading && !issues.length"
        variant="smooth"
        icon="add"
        size="tiny"
        @click="shoeCreateIssuePopup"
      >
        Create or Link Issue
      </woot-button>
    </div>
    <div v-if="isLoading" class="flex items-center justify-center">
      <span class="text-sm font-medium text-slate-800 dark:text-slate-100">
        Loading..
      </span>
    </div>

    <div v-if="!isLoading && issues.length" class="flex flex-col gap-2">
      <issue-item
        v-for="issue in issues"
        :key="issue.id"
        :issue="issue"
        :conversation-id="conversationId"
        @delete="deleteIssue"
      />
    </div>
    <woot-modal :show.sync="showAddPopup" :on-close="hideAddPopup">
      <add-issue
        :conversation-id="conversationId"
        :account-id="currentAccountId"
        @close="hideAddPopup"
      />
    </woot-modal>
  </div>
</template>
<script>
import { LinearClient } from '@linear/sdk';

import { mapGetters } from 'vuex';
import IssueItem from './IssueItem.vue';
import accountMixin from 'dashboard/mixins/account.js';
import AddIssue from './AddIssue.vue';

import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper.js';

// const chatwootAPIKey = '';
const localAPIKey = '';
const linearClient = new LinearClient({
  apiKey: localAPIKey,
});
// const BASE_URL = 'https:app.chatwoot.com';
const BASE_URL = 'http://localhost:3000';

export default {
  components: {
    IssueItem,
    AddIssue,
  },
  mixins: [accountMixin],
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
    shoeCreateIssuePopup() {
      this.showAddPopup = true;
    },
    hideAddPopup() {
      this.showAddPopup = false;
      this.loadIssues();
    },
    async loadIssues() {
      const url =
        BASE_URL +
        frontendURL(
          conversationUrl({
            accountId: this.accountId,
            id: this.conversationId,
          })
        );
      this.isLoading = true;
      linearClient.attachmentsForURL(url).then(issues => {
        if (issues.nodes.length) {
          issues.nodes.map(issue1 => {
            const linearIssueId = issue1._issue.id;
            const attachmentId = issue1.id;
            if (linearIssueId) {
              linearClient.issue(linearIssueId).then(issue2 => {
                console.log('Issue:', issue2, attachmentId);
                this.issues.push({
                  id: issue2.id,
                  title: issue2.title,
                  link: issue2.url,
                  identifier: issue2.identifier,
                  attachmentId,
                  ...issue2,
                });
                this.isLoading = false;
              });
            }
          });
        } else {
          this.isLoading = false;
          console.log('No issues');
        }
      });
    },
    async deleteIssue(issue) {
      const index = this.issues.findIndex(i => i.id === issue.id);
      if (index > -1) {
        this.issues.splice(index, 1);
      }
      await linearClient.deleteAttachment(issue.attachmentId);
    },
  },
};
</script>
<style scoped lang="scss">
.macros_list--empty-state {
  padding: var(--space-slab);
  p {
    margin: 0;
  }
}
.macros_add-button {
  margin: var(--space-small) auto 0;
}
</style>
