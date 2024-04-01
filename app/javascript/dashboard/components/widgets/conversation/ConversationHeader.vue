<template>
  <div
    class="bg-white dark:bg-slate-900 flex justify-between items-center py-2 px-4 border-b border-slate-50 dark:border-slate-800/50 flex-col md:flex-row"
  >
    <div
      class="flex-1 w-full min-w-0 flex flex-col items-center justify-center"
      :class="isInboxView ? 'sm:flex-row' : 'md:flex-row'"
    >
      <div class="flex justify-start items-center min-w-0 w-fit max-w-full">
        <back-button
          v-if="showBackButton"
          :back-url="backButtonUrl"
          class="ltr:ml-0 rtl:mr-0 rtl:ml-4"
        />
        <Thumbnail
          :src="currentContact.thumbnail"
          :badge="inboxBadge"
          :username="currentContact.name"
          :status="currentContact.availability_status"
        />
        <div
          class="items-start flex flex-col ml-2 rtl:ml-0 rtl:mr-2 min-w-0 w-fit overflow-hidden"
        >
          <div
            class="flex items-center flex-row gap-1 m-0 p-0 w-fit max-w-full"
          >
            <woot-button
              variant="link"
              color-scheme="secondary"
              class="[&>span]:overflow-hidden [&>span]:whitespace-nowrap [&>span]:text-ellipsis min-w-0"
              @click.prevent="$emit('contact-panel-toggle')"
            >
              <span
                class="text-base leading-tight font-medium text-slate-900 dark:text-slate-100"
              >
                {{ currentContact.name }}
              </span>
            </woot-button>
            <fluent-icon
              v-if="!isHMACVerified"
              v-tooltip="$t('CONVERSATION.UNVERIFIED_SESSION')"
              size="14"
              class="text-yellow-600 dark:text-yellow-500 my-0 mx-0 min-w-[14px]"
              icon="warning"
            />
          </div>

          <div
            class="conversation--header--actions items-center flex text-xs gap-2 text-ellipsis overflow-hidden whitespace-nowrap"
          >
            <inbox-name v-if="hasMultipleInboxes" :inbox="inbox" />
            <span
              v-if="isSnoozed"
              class="font-medium text-yellow-600 dark:text-yellow-500"
            >
              {{ snoozedDisplayText }}
            </span>
            <woot-button
              class="p-0"
              size="small"
              variant="link"
              @click="$emit('contact-panel-toggle')"
            >
              {{ contactPanelToggleText }}
            </woot-button>
          </div>
        </div>
      </div>
      <div
        class="header-actions-wrap items-center flex flex-row flex-grow justify-end mt-3 lg:mt-0"
        :class="{ 'justify-end': isContactPanelOpen }"
      >
        <more-actions :conversation-id="currentChat.id" />
      </div>
    </div>
  </div>
</template>
<script>
import { hasPressedAltAndOKey } from 'shared/helpers/KeyboardHelpers';
import { mapGetters } from 'vuex';
import agentMixin from '../../../mixins/agentMixin.js';
import BackButton from '../BackButton.vue';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import inboxMixin from 'shared/mixins/inboxMixin';
import InboxName from '../InboxName.vue';
import MoreActions from './MoreActions.vue';
import Thumbnail from '../Thumbnail.vue';
import wootConstants from 'dashboard/constants/globals';
import { conversationListPageURL } from 'dashboard/helper/URLHelper';
import { snoozedReopenTime } from 'dashboard/helper/snoozeHelpers';

export default {
  components: {
    BackButton,
    InboxName,
    MoreActions,
    Thumbnail,
  },
  mixins: [inboxMixin, agentMixin, eventListenerMixins],
  props: {
    chat: {
      type: Object,
      default: () => {},
    },
    isContactPanelOpen: {
      type: Boolean,
      default: false,
    },
    showBackButton: {
      type: Boolean,
      default: false,
    },
    isInboxView: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxAssignableAgents/getUIFlags',
      currentChat: 'getSelectedChat',
    }),
    chatMetadata() {
      return this.chat.meta;
    },
    backButtonUrl() {
      const {
        params: { accountId, inbox_id: inboxId, label, teamId },
        name,
      } = this.$route;
      return conversationListPageURL({
        accountId,
        inboxId,
        label,
        teamId,
        conversationType: name === 'conversation_mentions' ? 'mention' : '',
      });
    },
    isHMACVerified() {
      if (!this.isAWebWidgetInbox) {
        return true;
      }
      return this.chatMetadata.hmac_verified;
    },
    currentContact() {
      return this.$store.getters['contacts/getContact'](
        this.chat.meta.sender.id
      );
    },
    isSnoozed() {
      return this.currentChat.status === wootConstants.STATUS_TYPE.SNOOZED;
    },
    snoozedDisplayText() {
      const { snoozed_until: snoozedUntil } = this.currentChat;
      if (snoozedUntil) {
        return `${this.$t(
          'CONVERSATION.HEADER.SNOOZED_UNTIL'
        )} ${snoozedReopenTime(snoozedUntil)}`;
      }
      return this.$t('CONVERSATION.HEADER.SNOOZED_UNTIL_NEXT_REPLY');
    },
    contactPanelToggleText() {
      return `${
        this.isContactPanelOpen
          ? this.$t('CONVERSATION.HEADER.CLOSE')
          : this.$t('CONVERSATION.HEADER.OPEN')
      } ${this.$t('CONVERSATION.HEADER.DETAILS')}`;
    },
    inbox() {
      const { inbox_id: inboxId } = this.chat;
      return this.$store.getters['inboxes/getInbox'](inboxId);
    },
    hasMultipleInboxes() {
      return this.$store.getters['inboxes/getInboxes'].length > 1;
    },
  },

  methods: {
    handleKeyEvents(e) {
      if (hasPressedAltAndOKey(e)) {
        this.$emit('contact-panel-toggle');
      }
    },
  },
};
</script>

<style lang="scss" scoped>
.conversation--header--actions {
  ::v-deep .inbox--name {
    @apply m-0;
  }
}
</style>
