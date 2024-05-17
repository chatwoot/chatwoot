<template>
  <div class="relative" @mouseover="linkedIssue ? openIssue() : null">
    <woot-button
      v-on-clickaway="closeSlaPopover"
      v-tooltip="tooltipText"
      variant="clear"
      color-scheme="secondary"
      @click="openIssue()"
    >
      <fluent-icon
        icon="linear"
        size="19"
        class="text-[#5E6AD2]"
        view-box="0 0 19 19"
      />
      <span v-if="linkedIssue" class="text-xs font-medium text-ash-800">
        {{ linkedIssue.issue.identifier }}
      </span>
    </woot-button>
    <issue-item
      v-if="shouldShowIssue"
      :issue="linkedIssue.issue"
      :link-id="linkedIssue.id"
      class="absolute right-0 top-[46px]"
      @unlink-issue="unlinkIssue"
    />
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
import LinearAPI from 'dashboard/api/integrations/linear';
import CreateOrLinkIssue from './CreateOrLinkIssue.vue';
import alertMixin from 'shared/mixins/alertMixin';
export default {
  components: {
    IssueItem,
    CreateOrLinkIssue,
  },
  mixins: [alertMixin],
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  data() {
    return {
      linkedIssue: null,
      showIssue: false,
      showPopup: false,
    };
  },
  computed: {
    ...mapGetters({
      currentAccountId: 'getCurrentAccountId',
    }),
    shouldShowIssue() {
      return this.showIssue && this.linkedIssue;
    },
    tooltipText() {
      return this.linkedIssue === null
        ? this.$t('INTEGRATION_SETTINGS.LINEAR.ADD_OR_LINK_BUTTON')
        : null;
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
    closePopup() {
      this.showPopup = false;
      this.loadLinkedIssue();
    },
    async loadLinkedIssue() {
      try {
        const response = await LinearAPI.getLinkedIssue(this.conversationId);
        const issues = response.data;
        this.linkedIssue = issues && issues.length ? issues[0] : null;
      } catch (error) {
        this.showAlert(this.$t('INTEGRATION_SETTINGS.LINEAR.LOADING_ERROR'));
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
    openIssue() {
      if (!this.linkedIssue) this.showPopup = true;
      this.showIssue = true;
    },
    closeSlaPopover() {
      this.showIssue = false;
    },
  },
};
</script>
