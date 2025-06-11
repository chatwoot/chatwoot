<script>
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import BubbleActions from './bubble/Actions.vue';
import BubbleContact from './bubble/Contact.vue';
import BubbleFile from './bubble/File.vue';
import BubbleImageAudioVideo from './bubble/ImageAudioVideo.vue';
import BubbleIntegration from './bubble/Integration.vue';
import BubbleLocation from './bubble/Location.vue';
import BubbleMailHead from './bubble/MailHead.vue';
import BubbleReplyTo from './bubble/ReplyTo.vue';
import BubbleText from './bubble/Text.vue';
import ContextMenu from 'dashboard/modules/conversations/components/MessageContextMenu.vue';
import InstagramStory from './bubble/InstagramStory.vue';
import InstagramStoryReply from './bubble/InstagramStoryReply.vue';
import Spinner from 'shared/components/Spinner.vue';
import { CONTENT_TYPES } from 'shared/constants/contentType';
import { MESSAGE_TYPE, MESSAGE_STATUS } from 'shared/constants/messages';
import { generateBotMessageContent } from './helpers/botMessageContentHelper';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { ACCOUNT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { LocalStorage } from 'shared/helpers/localStorage';
import { getDayDifferenceFromNow } from 'shared/helpers/DateHelper';
import * as Sentry from '@sentry/vue';
import { useTrack } from 'dashboard/composables';
import { emitter } from 'shared/helpers/mitt';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    BubbleActions,
    BubbleContact,
    BubbleFile,
    BubbleImageAudioVideo,
    BubbleIntegration,
    BubbleLocation,
    BubbleMailHead,
    BubbleReplyTo,
    BubbleText,
    ContextMenu,
    InstagramStory,
    InstagramStoryReply,
    Spinner,
    NextButton,
  },
  props: {
    data: {
      type: Object,
      required: true,
    },
    isATweet: {
      type: Boolean,
      default: false,
    },
    isAFacebookInbox: {
      type: Boolean,
      default: false,
    },
    isInstagram: {
      type: Boolean,
      default: false,
    },
    isAWhatsAppChannel: {
      type: Boolean,
      default: false,
    },
    isAnEmailInbox: {
      type: Boolean,
      default: false,
    },
    inboxSupportsReplyTo: {
      type: Object,
      default: () => ({}),
    },
    inReplyTo: {
      type: Object,
      default: () => ({}),
    },
  },
  setup() {
    const { formatMessage } = useMessageFormatter();
    return {
      formatMessage,
    };
  },
  data() {
    return {
      showContextMenu: false,
      hasMediaLoadError: false,
      contextMenuPosition: {},
      showBackgroundHighlight: false,
    };
  },
  computed: {
    attachments() {
      // Here it is used to get sender and created_at for each attachment
      return this.data?.attachments.map(attachment => ({
        ...attachment,
        sender: this.data.sender || {},
        created_at: this.data.created_at || '',
      }));
    },
    hasOneDayPassed() {
      // Disable retry button if the message is failed and the message is older than 24 hours
      return getDayDifferenceFromNow(new Date(), this.data?.created_at) >= 1;
    },
    shouldRenderMessage() {
      return (
        this.hasAttachments ||
        this.data.content ||
        this.isEmailContentType ||
        this.isUnsupported ||
        this.isAnIntegrationMessage
      );
    },
    emailMessageContent() {
      const {
        html_content: { full: fullHTMLContent } = {},
        text_content: { full: fullTextContent } = {},
      } = this.contentAttributes.email || {};

      if (fullHTMLContent) {
        return fullHTMLContent;
      }

      if (fullTextContent) {
        return fullTextContent.replace(/\n/g, '<br>');
      }

      return '';
    },
    displayQuotedButton() {
      if (this.emailMessageContent.includes('<blockquote')) {
        return true;
      }

      if (!this.isIncoming) {
        return false;
      }

      return false;
    },
    message() {
      // If the message is an email, emailMessageContent would be present
      // In that case, we would use letter package to render the email
      if (this.emailMessageContent && this.isIncoming) {
        return this.emailMessageContent;
      }

      const botMessageContent = generateBotMessageContent(
        this.contentType,
        this.contentAttributes,
        {
          noResponseText: this.$t('CONVERSATION.NO_RESPONSE'),
          csat: {
            ratingTitle: this.$t('CONVERSATION.RATING_TITLE'),
            feedbackTitle: this.$t('CONVERSATION.FEEDBACK_TITLE'),
          },
        }
      );

      if (this.contentType === 'input_csat') {
        return this.$t('CONVERSATION.CSAT_REPLY_MESSAGE') + botMessageContent;
      }

      return (
        this.formatMessage(
          this.data.content,
          this.isATweet,
          this.data.private
        ) + botMessageContent
      );
    },
    inReplyToMessageId() {
      // Why not use the inReplyTo object directly?
      // Glad you asked! The inReplyTo object may or may not be available
      // depending on the current scroll position of the message list
      // since old messages are only loaded when the user scrolls up
      return this.data.content_attributes?.in_reply_to;
    },
    isAnInstagramStory() {
      return this.contentAttributes.image_type === 'story_mention';
    },
    contextMenuEnabledOptions() {
      return {
        copy: this.hasText,
        delete:
          (this.hasText || this.hasAttachments) &&
          !this.isMessageDeleted &&
          !this.isFailed,
        cannedResponse:
          this.isOutgoing && this.hasText && !this.isMessageDeleted,
        copyLink: !this.isFailed || !this.isProcessing,
        translate:
          (!this.isFailed || !this.isProcessing) &&
          !this.isMessageDeleted &&
          this.hasText,
        replyTo: !this.data.private && this.inboxSupportsReplyTo.outgoing,
      };
    },
    contentAttributes() {
      return this.data.content_attributes || {};
    },
    externalError() {
      return this.contentAttributes.external_error || '';
    },
    sender() {
      return this.data.sender || {};
    },
    status() {
      return this.data.status;
    },
    storySender() {
      return this.contentAttributes.story_sender || null;
    },
    storyId() {
      return this.contentAttributes.story_id || null;
    },
    storyUrl() {
      return this.contentAttributes.story_url || null;
    },
    contentType() {
      const {
        data: { content_type: contentType },
      } = this;
      return contentType;
    },
    twitterProfileLink() {
      const additionalAttributes = this.sender.additional_attributes || {};
      const { screen_name: screenName } = additionalAttributes;
      return `https://twitter.com/${screenName}`;
    },
    alignBubble() {
      const { message_type: messageType } = this.data;
      const isCentered = messageType === MESSAGE_TYPE.ACTIVITY;
      const isLeftAligned = messageType === MESSAGE_TYPE.INCOMING;
      const isRightAligned =
        messageType === MESSAGE_TYPE.OUTGOING ||
        messageType === MESSAGE_TYPE.TEMPLATE;
      return {
        center: isCentered,
        left: isLeftAligned,
        right: isRightAligned,
        'has-context-menu': this.showContextMenu,
        // this handles the offset required to align the context menu button
        // extra alignment is required since a tweet message has a the user name and avatar below it
        'has-tweet-menu': this.isATweet,
        'has-bg': this.showBackgroundHighlight,
      };
    },
    createdAt() {
      return this.contentAttributes.external_created_at || this.data.created_at;
    },
    isBubble() {
      return [0, 1, 3].includes(this.data.message_type);
    },
    isIncoming() {
      return this.data.message_type === MESSAGE_TYPE.INCOMING;
    },
    isOutgoing() {
      return this.data.message_type === MESSAGE_TYPE.OUTGOING;
    },
    isTemplate() {
      return this.data.message_type === MESSAGE_TYPE.TEMPLATE;
    },
    isAnIntegrationMessage() {
      return this.contentType === 'integrations';
    },
    emailHeadAttributes() {
      return {
        email: this.contentAttributes.email,
        cc: this.contentAttributes.cc_emails,
        bcc: this.contentAttributes.bcc_emails,
      };
    },
    hasAttachments() {
      return !!(this.data.attachments && this.data.attachments.length > 0);
    },
    isMessageDeleted() {
      return this.contentAttributes.deleted;
    },
    hasText() {
      return !!this.data.content;
    },
    tooltipForSender() {
      const name = this.senderNameForAvatar;
      const { message_type: messageType } = this.data;
      const showTooltip =
        messageType === MESSAGE_TYPE.OUTGOING ||
        messageType === MESSAGE_TYPE.TEMPLATE;
      return showTooltip
        ? {
            content: `${this.$t('CONVERSATION.SENT_BY')} ${name}`,
          }
        : false;
    },
    errorMessageTooltip() {
      if (this.isFailed) {
        return this.externalError || this.$t(`CONVERSATION.SEND_FAILED`);
      }
      return '';
    },
    wrapClass() {
      return {
        wrap: this.isBubble,
        'activity-wrap': !this.isBubble,
        'is-pending': this.isPending,
        'is-failed': this.isFailed,
        'is-email': this.isEmailContentType,
      };
    },
    bubbleClass() {
      return {
        bubble: this.isBubble,
        'is-private': this.data.private,
        'is-unsupported': this.isUnsupported,
        'is-image': this.hasMediaAttachment('image'),
        'is-video': this.hasMediaAttachment('video'),
        'is-text': this.hasText,
        'is-from-bot': this.isSentByBot,
        'is-failed': this.isFailed,
        'is-email': this.isEmailContentType,
      };
    },
    isUnsupported() {
      return this.contentAttributes.is_unsupported ?? false;
    },
    isPending() {
      return this.data.status === MESSAGE_STATUS.PROGRESS;
    },
    isFailed() {
      return this.data.status === MESSAGE_STATUS.FAILED;
    },
    isSentByBot() {
      if (this.isPending || this.isFailed) return false;
      return !this.sender.type || this.sender.type === 'agent_bot';
    },
    shouldShowContextMenu() {
      return !this.isUnsupported;
    },
    showAvatar() {
      if (this.isOutgoing || this.isTemplate) {
        return true;
      }
      return this.isATweet && this.isIncoming && this.sender;
    },
    senderNameForAvatar() {
      if (this.isOutgoing || this.isTemplate) {
        const { name = this.$t('CONVERSATION.BOT') } = this.sender || {};
        return name;
      }
      return '';
    },
    isEmailContentType() {
      return this.contentType === CONTENT_TYPES.INCOMING_EMAIL;
    },
  },
  watch: {
    data() {
      this.hasMediaLoadError = false;
    },
  },
  mounted() {
    this.hasMediaLoadError = false;
    emitter.on(BUS_EVENTS.ON_MESSAGE_LIST_SCROLL, this.closeContextMenu);
    this.setupHighlightTimer();
  },
  unmounted() {
    emitter.off(BUS_EVENTS.ON_MESSAGE_LIST_SCROLL, this.closeContextMenu);
    clearTimeout(this.higlightTimeout);
  },
  methods: {
    isAttachmentImageVideoAudio(fileType) {
      return ['image', 'audio', 'video', 'story_mention', 'ig_reel'].includes(
        fileType
      );
    },
    hasMediaAttachment(type) {
      if (this.hasAttachments && this.data.attachments.length > 0) {
        return this.compareMessageFileType(this.data, type);
      }
      return false;
    },
    compareMessageFileType(messageData, type) {
      try {
        const { attachments = [{}] } = messageData;
        const { file_type: fileType } = attachments[0];
        return fileType === type && !this.hasMediaLoadError;
      } catch (err) {
        Sentry.setContext('attachment-parsing-error', {
          messageData,
          type,
          hasMediaLoadError: this.hasMediaLoadError,
        });

        Sentry.captureException(err);
        return false;
      }
    },
    handleContextMenuClick() {
      this.showContextMenu = !this.showContextMenu;
    },
    async retrySendMessage() {
      await this.$store.dispatch('sendMessageWithData', this.data);
    },
    onMediaLoadError() {
      this.hasMediaLoadError = true;
    },
    openContextMenu(e) {
      const shouldSkipContextMenu =
        e.target?.classList.contains('skip-context-menu') ||
        e.target?.tagName.toLowerCase() === 'a';
      if (shouldSkipContextMenu || getSelection().toString()) {
        return;
      }

      e.preventDefault();
      if (e.type === 'contextmenu') {
        useTrack(ACCOUNT_EVENTS.OPEN_MESSAGE_CONTEXT_MENU);
      }
      this.contextMenuPosition = {
        x: e.pageX || e.clientX,
        y: e.pageY || e.clientY,
      };
      this.showContextMenu = true;
    },
    closeContextMenu() {
      this.showContextMenu = false;
      this.contextMenuPosition = { x: null, y: null };
    },
    handleReplyTo() {
      const replyStorageKey = LOCAL_STORAGE_KEYS.MESSAGE_REPLY_TO;
      const { conversation_id: conversationId, id: replyTo } = this.data;

      LocalStorage.updateJsonStore(replyStorageKey, conversationId, replyTo);
      emitter.emit(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, this.data);
    },
    setupHighlightTimer() {
      if (Number(this.$route.query.messageId) !== Number(this.data.id)) {
        return;
      }

      this.showBackgroundHighlight = true;
      const HIGHLIGHT_TIMER = 1000;
      this.higlightTimeout = setTimeout(() => {
        this.showBackgroundHighlight = false;
      }, HIGHLIGHT_TIMER);
    },
  },
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <li
    v-if="shouldRenderMessage"
    :id="`message${data.id}`"
    class="group/context-menu"
    :class="[alignBubble]"
  >
    <div :class="wrapClass">
      <div
        v-if="isFailed && !hasOneDayPassed && !isAnEmailInbox"
        class="message-failed--alert"
      >
        <NextButton
          v-tooltip.top-end="$t('CONVERSATION.TRY_AGAIN')"
          ghost
          xs
          ruby
          icon="i-lucide-refresh-ccw"
          @click="retrySendMessage"
        />
      </div>
      <div :class="bubbleClass" @contextmenu="openContextMenu($event)">
        <BubbleMailHead
          :email-attributes="contentAttributes.email"
          :cc="emailHeadAttributes.cc"
          :bcc="emailHeadAttributes.bcc"
          :is-incoming="isIncoming"
        />
        <InstagramStoryReply v-if="storyUrl" :story-url="storyUrl" />
        <BubbleReplyTo
          v-if="inReplyToMessageId && inboxSupportsReplyTo.incoming"
          :message="inReplyTo"
          :message-type="data.message_type"
          :parent-has-attachments="hasAttachments"
        />
        <div v-if="isUnsupported">
          <template v-if="isAFacebookInbox && isInstagram">
            {{ $t('CONVERSATION.UNSUPPORTED_MESSAGE_INSTAGRAM') }}
          </template>
          <template v-else-if="isAFacebookInbox">
            {{ $t('CONVERSATION.UNSUPPORTED_MESSAGE_FACEBOOK') }}
          </template>
          <template v-else>
            {{ $t('CONVERSATION.UNSUPPORTED_MESSAGE') }}
          </template>
        </div>
        <BubbleText
          v-else-if="data.content"
          :message="message"
          :is-email="isEmailContentType"
          :display-quoted-button="displayQuotedButton"
        />
        <BubbleIntegration
          :message-id="data.id"
          :content-attributes="contentAttributes"
          :inbox-id="data.inbox_id"
        />
        <span
          v-if="isPending && hasAttachments"
          class="chat-bubble has-attachment agent"
        >
          {{ $t('CONVERSATION.UPLOADING_ATTACHMENTS') }}
        </span>
        <div v-if="!isPending && hasAttachments">
          <div v-for="attachment in attachments" :key="attachment.id">
            <InstagramStory
              v-if="isAnInstagramStory"
              :story-url="attachment.data_url"
              @error="onMediaLoadError"
            />
            <BubbleImageAudioVideo
              v-else-if="isAttachmentImageVideoAudio(attachment.file_type)"
              :attachment="attachment"
              @error="onMediaLoadError"
            />
            <BubbleLocation
              v-else-if="attachment.file_type === 'location'"
              :latitude="attachment.coordinates_lat"
              :longitude="attachment.coordinates_long"
              :name="attachment.fallback_title"
            />
            <BubbleContact
              v-else-if="attachment.file_type === 'contact'"
              :name="data.content"
              :phone-number="attachment.fallback_title"
            />
            <BubbleFile v-else :url="attachment.data_url" />
          </div>
        </div>
        <BubbleActions
          :id="data.id"
          :sender="data.sender"
          :story-sender="storySender"
          :external-error="errorMessageTooltip"
          :story-id="`${storyId}`"
          :is-a-tweet="isATweet"
          :is-a-whatsapp-channel="isAWhatsAppChannel"
          :is-email="isEmailContentType"
          :is-private="data.private"
          :message-type="data.message_type"
          :message-status="status"
          :source-id="data.source_id"
          :inbox-id="data.inbox_id"
          :created-at="createdAt"
        />
      </div>
      <Spinner v-if="isPending" size="tiny" />
      <div
        v-if="showAvatar"
        v-tooltip.left="tooltipForSender"
        class="sender--info"
      >
        <woot-thumbnail
          :src="sender.thumbnail"
          :username="senderNameForAvatar"
          size="16px"
        />
        <a
          v-if="isATweet && isIncoming"
          class="sender--available-name"
          :href="twitterProfileLink"
          target="_blank"
          rel="noopener noreferrer nofollow"
        >
          {{ sender.name }}
        </a>
      </div>
    </div>
    <div v-if="shouldShowContextMenu" class="context-menu-wrap">
      <ContextMenu
        v-if="isBubble && !isMessageDeleted"
        :context-menu-position="contextMenuPosition"
        :is-open="showContextMenu"
        :enabled-options="contextMenuEnabledOptions"
        :message="data"
        @open="openContextMenu"
        @close="closeContextMenu"
        @reply-to="handleReplyTo"
      />
    </div>
  </li>
</template>

<style lang="scss">
.wrap {
  > .bubble {
    @apply min-w-[128px];

    &.is-unsupported {
      @apply text-xs max-w-[300px] border-dashed border border-slate-200 text-slate-600 dark:text-slate-200 bg-slate-50 dark:bg-slate-700 dark:border-slate-500;

      .message-text--metadata .time {
        @apply text-slate-400 dark:text-slate-300;
      }
    }

    &.is-image,
    &.is-video {
      @apply p-0 overflow-hidden;

      .image,
      .video {
        @apply max-w-[20rem] p-0.5;

        > img,
        > video {
          /** ensure that the bubble radius and image radius match*/
          @apply rounded-[0.4rem];
        }

        > video {
          @apply h-full w-full object-cover;
        }
      }

      .video {
        @apply h-[11.25rem];
      }
    }

    &.is-image.is-text > .message-text__wrap,
    &.is-video.is-text > .message-text__wrap {
      @apply max-w-[20rem] py-2 px-4;
    }

    &.is-private .file.message-text__wrap {
      .file--icon {
        @apply text-woot-400 dark:text-woot-400;
      }

      .attachment-name {
        @apply text-slate-700 dark:text-slate-200;
      }

      .download.button {
        @apply text-woot-400 dark:text-woot-400;
      }
    }

    &.is-private.is-text > .message-text__wrap .link {
      @apply text-woot-600 dark:text-woot-200;
    }

    &.is-private.is-text > .message-text__wrap .prosemirror-mention-node {
      @apply font-bold bg-none rounded-sm p-0 bg-yellow-100 dark:bg-yellow-700 text-slate-700 dark:text-slate-25 underline;
    }

    &.is-from-bot {
      @apply bg-violet-400 dark:bg-violet-400;

      .message-text--metadata .time {
        @apply text-violet-50 dark:text-violet-50;
      }

      &.is-private .message-text--metadata .time {
        @apply text-slate-400 dark:text-slate-400;
      }
    }

    &.is-failed {
      @apply bg-n-ruby-4 dark:bg-n-ruby-4 text-n-slate-12;

      .message-text--metadata .time {
        @apply text-n-ruby-12 dark:text-n-ruby-12;
      }
    }
  }

  &.is-pending {
    @apply relative opacity-80;

    .spinner {
      @apply absolute bottom-1 right-1;
    }

    > .is-image.is-text.bubble > .message-text__wrap {
      @apply p-0;
    }
  }
}

.wrap.is-email {
  --bubble-max-width: 84% !important;
}

.sender--info {
  @apply items-center text-black-700 dark:text-black-100 inline-flex py-1 px-0;

  .sender--available-name {
    @apply text-xs ml-1;
  }
}

.message-failed--alert {
  @apply text-red-900 dark:text-red-900 flex-grow text-right mt-1 mr-1 mb-0 ml-0;
}

li.left,
li.right {
  @apply flex items-end;
}

li.left.has-tweet-menu .context-menu {
  // this handles the offset required to align the context menu button
  // extra alignment is required since a tweet message has a the user name and avatar below it
  @apply mb-6;
}

li.has-bg {
  @apply bg-woot-75 dark:bg-woot-600;
}

li.right .context-menu-wrap {
  @apply ml-auto;
}

li.right {
  @apply flex-row-reverse justify-end;

  .wrap.is-pending {
    @apply ml-auto;
  }

  .wrap.is-failed {
    @apply flex items-end ltr:ml-auto rtl:mr-auto;
  }
}

.has-context-menu {
  @apply bg-slate-50 dark:bg-slate-700;
}

.context-menu {
  @apply relative;
}

/* Markdown styling */

.bubble .text-content {
  p code {
    @apply bg-slate-75 dark:bg-slate-700 inline-block leading-none rounded-sm p-1;
  }

  ol li {
    @apply list-item list-decimal;
  }

  pre {
    @apply bg-slate-75 dark:bg-slate-700 block border-slate-75 dark:border-slate-700 text-slate-800 dark:text-slate-100 rounded-md p-2 mt-1 mb-2 leading-relaxed whitespace-pre-wrap;

    code {
      @apply bg-transparent text-slate-800 dark:text-slate-100 p-0;
    }
  }

  blockquote {
    @apply border-l-4 mx-0 my-1 pt-2 pr-2 pb-0 pl-4 border-slate-75 border-solid dark:border-slate-600 text-slate-800 dark:text-slate-100;

    p {
      @apply text-slate-800 dark:text-slate-300;
    }
  }
}

.right .bubble .text-content {
  p code {
    @apply bg-woot-600 dark:bg-woot-600 text-white dark:text-white;
  }

  pre {
    @apply bg-woot-800 dark:bg-woot-800 border-woot-700 dark:border-woot-700 text-white dark:text-white;

    code {
      @apply bg-transparent text-white dark:text-white;
    }
  }

  blockquote {
    @apply border-l-4 border-solid border-woot-400 dark:border-woot-400 text-white dark:text-white;

    p {
      @apply text-woot-75 dark:text-woot-75;
    }
  }
}
</style>
