<template>
  <div class="relative" @mouseover="openSlaPopover()">
    <woot-button
      v-on-clickaway="closeSlaPopover"
      variant="clear"
      color-scheme="secondary"
      @click="openSlaPopover()"
    >
      <fluent-icon
        icon="linear"
        size="19"
        class="text-[#5E6AD2]"
        view-box="0 0 19 19"
      />
    </woot-button>
    <linear-issue-details
      v-if="showSlaPopoverCard"
      :issue="linkedIssue.issue"
      class="absolute right-0 top-[46px]"
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
import LinearIssueDetails from './LinearIssueDetails.vue';
import LinearAPI from 'dashboard/api/integrations/linear';
import CreateOrLinkIssue from './CreateOrLinkIssue.vue';

export default {
  components: {
    LinearIssueDetails,
    CreateOrLinkIssue,
  },
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  data() {
    return {
      linkedIssue: null,
      showSlaPopover: false,
      showPopup: false,
    };
  },
  computed: {
    ...mapGetters({
      currentAccountId: 'getCurrentAccountId',
    }),
    showSlaPopoverCard() {
      return this.showSlaPopover && this.linkedIssue;
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
    openSlaPopover() {
      if (!this.linkedIssue) this.showPopup = true;
      this.showSlaPopover = true;
    },
    closeSlaPopover() {
      this.showSlaPopover = false;
    },
  },
};
</script>
