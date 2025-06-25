<template>
  <div class="conv-header">
    <div class="conversation-header--details">
      <div class="user">
        <back-button v-if="showBackButton" :back-url="backButtonUrl" />
        <Thumbnail
          :src="currentContact.thumbnail"
          :badge="inboxBadge"
          :username="currentContact.name"
          :status="currentContact.availability_status"
        />
        <div class="user--profile__meta">
          <woot-button
            variant="link"
            color-scheme="secondary"
            class="text-truncate"
            @click.prevent="$emit('contact-panel-toggle')"
          >
            <h3 class="sub-block-title user--name text-truncate">
              <span>{{ currentContact.name }}</span>
              <fluent-icon
                v-if="!isHMACVerified"
                v-tooltip="$t('CONVERSATION.UNVERIFIED_SESSION')"
                size="14"
                class="hmac-warning__icon"
                icon="warning"
              />
            </h3>
          </woot-button>
          <div class="conversation--header--actions text-truncate">
            <inbox-name v-if="hasMultipleInboxes" :inbox="inbox" />
            <span v-if="isSnoozed" class="snoozed--display-text">
              {{ snoozedDisplayText }}
            </span>
            <woot-button
              class="user--profile__button"
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
        class="header-actions-wrap"
        :class="{ 'has-open-sidebar': isContactPanelOpen }"
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
import BackButton from '../BackButton';
import differenceInHours from 'date-fns/differenceInHours';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import inboxMixin from 'shared/mixins/inboxMixin';
import InboxName from '../InboxName';
import MoreActions from './MoreActions';
import Thumbnail from '../Thumbnail';
import wootConstants from 'dashboard/constants/globals';
import { conversationListPageURL } from 'dashboard/helper/URLHelper';
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
        // When the snooze is applied, it schedules the unsnooze event to next day/week 9AM.
        // By that logic if the time difference is less than or equal to 24 + 9 hours we can consider it tomorrow.
        const MAX_TIME_DIFFERENCE = 33;
        const isSnoozedUntilTomorrow =
          differenceInHours(new Date(snoozedUntil), new Date()) <=
          MAX_TIME_DIFFERENCE;
        return this.$t(
          isSnoozedUntilTomorrow
            ? 'CONVERSATION.HEADER.SNOOZED_UNTIL_TOMORROW'
            : 'CONVERSATION.HEADER.SNOOZED_UNTIL_NEXT_WEEK'
        );
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
@import '~dashboard/assets/scss/woot';

.conv-header {
  flex: 0 0 var(--space-jumbo);
  flex-direction: row;

  @include breakpoint(medium up) {
    flex-direction: column;
  }
}

.conversation-header--details {
  display: flex;
  justify-content: center;
  flex-direction: column;
  align-items: center;
  width: 100%;

  @include breakpoint(medium up) {
    flex-direction: row;
  }
}

.option__desc {
  display: flex;
  align-items: center;
}

.option__desc {
  &::v-deep .status-badge {
    margin-right: var(--space-small);
    min-width: 0;
    flex-shrink: 0;
  }
}

.user--name {
  display: inline-block;
  line-height: 1.2;
  text-transform: capitalize;
  margin: 0;
  padding: 0;
}

.conversation--header--actions {
  align-items: center;
  display: flex;
  font-size: var(--font-size-mini);
  gap: var(--space-small);

  ::v-deep .inbox--name {
    margin: 0;
  }

  .user--profile__button {
    padding: 0;
  }

  .snoozed--display-text {
    font-weight: var(--font-weight-medium);
    color: var(--y-600);
  }
}

.hmac-warning__icon {
  color: var(--y-600);
  margin: 0 var(--space-micro);
}
</style>
