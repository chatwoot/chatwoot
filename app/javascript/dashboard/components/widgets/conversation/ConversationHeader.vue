<template>
  <div class="conv-header">
    <div class="user">
      <Thumbnail
        :src="currentContact.thumbnail"
        size="40px"
        :badge="inboxBadge"
        :username="currentContact.name"
        :status="currentContact.availability_status"
      />
      <div class="user--profile__meta">
        <h3 class="user--name text-truncate">
          {{ currentContact.name }}
        </h3>
        <div class="conversation--header--actions">
          <inbox-name :inbox="inbox" class="margin-right-small" />
          <span
            v-if="isSnoozed"
            class="snoozed--display-text margin-right-small"
          >
            {{ snoozedDisplayText }}
          </span>
          <woot-button
            class="user--profile__button margin-right-small"
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
</template>
<script>
import { mapGetters } from 'vuex';
import MoreActions from './MoreActions';
import Thumbnail from '../Thumbnail';
import agentMixin from '../../../mixins/agentMixin.js';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import inboxMixin from 'shared/mixins/inboxMixin';
import { hasPressedAltAndOKey } from 'shared/helpers/KeyboardHelpers';
import wootConstants from '../../../constants';
import differenceInHours from 'date-fns/differenceInHours';
import InboxName from '../InboxName';

export default {
  components: {
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
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxAssignableAgents/getUIFlags',
      currentChat: 'getSelectedChat',
    }),

    chatMetadata() {
      return this.chat.meta;
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
.text-truncate {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.conv-header {
  flex: 0 0 var(--space-jumbo);
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
  font-size: var(--font-size-medium);
  line-height: 1.3;
  margin: 0;
  text-transform: capitalize;
  width: 100%;
}

.conversation--header--actions {
  align-items: center;
  display: flex;
  font-size: var(--font-size-mini);

  .user--profile__button {
    padding: 0;
  }

  .snoozed--display-text {
    font-weight: var(--font-weight-medium);
    color: var(--y-900);
  }
}
</style>
