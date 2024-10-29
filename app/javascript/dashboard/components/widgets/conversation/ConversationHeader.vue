<script>
import { mapGetters } from 'vuex';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import BackButton from '../BackButton.vue';
import inboxMixin from 'shared/mixins/inboxMixin';
import InboxName from '../InboxName.vue';
import MoreActions from './MoreActions.vue';
import Thumbnail from '../Thumbnail.vue';
import SLACardLabel from './components/SLACardLabel.vue';
import wootConstants from 'dashboard/constants/globals';
import { conversationListPageURL } from 'dashboard/helper/URLHelper';
import { snoozedReopenTime } from 'dashboard/helper/snoozeHelpers';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import Linear from './linear/index.vue';

export default {
  components: {
    BackButton,
    InboxName,
    MoreActions,
    Thumbnail,
    SLACardLabel,
    Linear,
  },
  mixins: [inboxMixin],
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
  emits: ['contactPanelToggle'],
  setup(props, { emit }) {
    const keyboardEvents = {
      'Alt+KeyO': {
        action: () => emit('contactPanelToggle'),
      },
    };
    useKeyboardEvents(keyboardEvents);
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
      appIntegrations: 'integrations/getAppIntegrations',
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
    hasSlaPolicyId() {
      return this.chat?.sla_policy_id;
    },
    isLinearIntegrationEnabled() {
      return this.appIntegrations.find(
        integration => integration.id === 'linear' && !!integration.hooks.length
      );
    },
    isLinearFeatureEnabled() {
      return this.isFeatureEnabledonAccount(
        this.accountId,
        FEATURE_FLAGS.LINEAR
      );
    },
  },
};
</script>

<template>
  <div
    class="flex flex-col items-center justify-between px-4 py-2 bg-white border-b dark:bg-slate-900 border-slate-50 dark:border-slate-800/50 md:flex-row"
  >
    <div
      class="flex flex-col items-center justify-center flex-1 w-full min-w-0"
      :class="isInboxView ? 'sm:flex-row' : 'md:flex-row'"
    >
      <div class="flex items-center justify-start max-w-full min-w-0 w-fit">
        <BackButton
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
          class="flex flex-col items-start min-w-0 ml-2 overflow-hidden rtl:ml-0 rtl:mr-2 w-fit"
        >
          <div
            class="flex flex-row items-center max-w-full gap-1 p-0 m-0 w-fit"
          >
            <woot-button
              variant="link"
              color-scheme="secondary"
              class="[&>span]:overflow-hidden [&>span]:whitespace-nowrap [&>span]:text-ellipsis min-w-0"
              @click.prevent="$emit('contactPanelToggle')"
            >
              <span
                class="text-base font-medium leading-tight text-slate-900 dark:text-slate-100"
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
            class="flex items-center gap-2 overflow-hidden text-xs conversation--header--actions text-ellipsis whitespace-nowrap"
          >
            <InboxName v-if="hasMultipleInboxes" :inbox="inbox" />
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
              @click="$emit('contactPanelToggle')"
            >
              {{ contactPanelToggleText }}
            </woot-button>
          </div>
        </div>
      </div>
      <div
        class="flex flex-row items-center justify-end flex-grow gap-2 mt-3 header-actions-wrap lg:mt-0"
        :class="{ 'justify-end': isContactPanelOpen }"
      >
        <SLACardLabel v-if="hasSlaPolicyId" :chat="chat" show-extended-info />
        <Linear
          v-if="isLinearIntegrationEnabled && isLinearFeatureEnabled"
          :conversation-id="currentChat.id"
        />
        <MoreActions :conversation-id="currentChat.id" />
      </div>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.conversation--header--actions {
  ::v-deep .inbox--name {
    @apply m-0;
  }
}
</style>
