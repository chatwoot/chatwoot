<template>
  <li v-if="shouldRenderMessage" :id="`message${data.id}`" :class="alignBubble">
    <div :class="wrapClass">
      <div
        v-tooltip.top-start="messageToolTip"
        :class="bubbleClass"
        @contextmenu="openContextMenu($event)"
      >
        <bubble-mail-head
          :email-attributes="contentAttributes.email"
          :cc="emailHeadAttributes.cc"
          :bcc="emailHeadAttributes.bcc"
          :is-incoming="isIncoming"
        />
        <bubble-text
          v-if="data.content"
          :message="message"
          :is-email="isEmailContentType"
          :display-quoted-button="displayQuotedButton"
        />
        <bubble-integration
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
          <div v-for="attachment in data.attachments" :key="attachment.id">
            <bubble-image
              v-if="attachment.file_type === 'image' && !hasImageError"
              :url="attachment.data_url"
              @error="onImageLoadError"
            />
            <audio
              v-else-if="attachment.file_type === 'audio'"
              controls
              class="skip-context-menu"
            >
              <source :src="attachment.data_url" />
            </audio>
            <bubble-video
              v-else-if="attachment.file_type === 'video'"
              :url="attachment.data_url"
            />
            <bubble-location
              v-else-if="attachment.file_type === 'location'"
              :latitude="attachment.coordinates_lat"
              :longitude="attachment.coordinates_long"
              :name="attachment.fallback_title"
            />
            <bubble-contact
              v-else-if="attachment.file_type === 'contact'"
              :name="data.content"
              :phone-number="attachment.fallback_title"
            />
            <instagram-image-error-placeholder
              v-else-if="hasImageError && hasInstagramStory"
            />
            <bubble-file v-else :url="attachment.data_url" />
          </div>
        </div>
        <bubble-actions
          :id="data.id"
          :sender="data.sender"
          :story-sender="storySender"
          :story-id="storyId"
          :is-a-tweet="isATweet"
          :is-a-whatsapp-channel="isAWhatsAppChannel"
          :has-instagram-story="hasInstagramStory"
          :is-email="isEmailContentType"
          :is-private="data.private"
          :message-type="data.message_type"
          :message-status="status"
          :source-id="data.source_id"
          :inbox-id="data.inbox_id"
          :created-at="createdAt"
        />
      </div>
      <spinner v-if="isPending" size="tiny" />
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
      <div v-if="isFailed" class="message-failed--alert">
        <woot-button
          v-tooltip.top-end="$t('CONVERSATION.TRY_AGAIN')"
          size="tiny"
          color-scheme="alert"
          variant="clear"
          icon="arrow-clockwise"
          @click="retrySendMessage"
        />
      </div>
    </div>
    <div v-if="shouldShowContextMenu" class="context-menu-wrap">
      <context-menu
        v-if="isBubble && !isMessageDeleted"
        :context-menu-position="contextMenuPosition"
        :is-open="showContextMenu"
        :enabled-options="contextMenuEnabledOptions"
        :message="data"
        @open="openContextMenu"
        @close="closeContextMenu"
      />
    </div>
  </li>
</template>
<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import BubbleActions from './bubble/Actions';
import BubbleFile from './bubble/File';
import BubbleImage from './bubble/Image';
import BubbleIntegration from './bubble/Integration.vue';
import BubbleLocation from './bubble/Location';
import BubbleMailHead from './bubble/MailHead';
import BubbleText from './bubble/Text';
import BubbleVideo from './bubble/Video.vue';
import BubbleContact from './bubble/Contact';
import Spinner from 'shared/components/Spinner';
import ContextMenu from 'dashboard/modules/conversations/components/MessageContextMenu';
import instagramImageErrorPlaceholder from './instagramImageErrorPlaceholder.vue';
import alertMixin from 'shared/mixins/alertMixin';
import contentTypeMixin from 'shared/mixins/contentTypeMixin';
import { MESSAGE_TYPE, MESSAGE_STATUS } from 'shared/constants/messages';
import { generateBotMessageContent } from './helpers/botMessageContentHelper';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { ACCOUNT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

export default {
  components: {
    BubbleActions,
    BubbleFile,
    BubbleImage,
    BubbleIntegration,
    BubbleLocation,
    BubbleMailHead,
    BubbleText,
    BubbleVideo,
    BubbleContact,
    ContextMenu,
    Spinner,
    instagramImageErrorPlaceholder,
  },
  mixins: [alertMixin, messageFormatterMixin, contentTypeMixin],
  props: {
    data: {
      type: Object,
      required: true,
    },
    isATweet: {
      type: Boolean,
      default: false,
    },
    isAWhatsAppChannel: {
      type: Boolean,
      default: false,
    },
    hasInstagramStory: {
      type: Boolean,
      default: false,
    },
    isWebWidgetInbox: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      showContextMenu: false,
      hasImageError: false,
      contextMenuPosition: {},
      showBackgroundHighlight: false,
    };
  },
  computed: {
    shouldRenderMessage() {
      return (
        this.hasAttachments ||
        this.data.content ||
        this.isEmailContentType ||
        this.isAnIntegrationMessage
      );
    },
    emailMessageContent() {
      const {
        html_content: { full: fullHTMLContent } = {},
        text_content: { full: fullTextContent } = {},
      } = this.contentAttributes.email || {};
      return fullHTMLContent || fullTextContent || '';
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
    contextMenuEnabledOptions() {
      return {
        copy: this.hasText,
        delete: this.hasText || this.hasAttachments,
        cannedResponse: this.isOutgoing && this.hasText,
      };
    },
    contentAttributes() {
      return this.data.content_attributes || {};
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
    messageToolTip() {
      if (this.isMessageDeleted) {
        return false;
      }
      if (this.isFailed) {
        return this.$t(`CONVERSATION.SEND_FAILED`);
      }
      return false;
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
        'is-image': this.hasMediaAttachment('image'),
        'is-video': this.hasMediaAttachment('video'),
        'is-text': this.hasText,
        'is-from-bot': this.isSentByBot,
        'is-failed': this.isFailed,
        'is-email': this.isEmailContentType,
      };
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
      return !(this.isFailed || this.isPending);
    },
    errorMessage() {
      const { meta } = this.data;
      return meta ? meta.error : '';
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
  },
  watch: {
    data() {
      this.hasImageError = false;
    },
  },
  mounted() {
    this.hasImageError = false;
    bus.$on(BUS_EVENTS.ON_MESSAGE_LIST_SCROLL, this.closeContextMenu);
    this.setupHighlightTimer();
  },
  beforeDestroy() {
    bus.$off(BUS_EVENTS.ON_MESSAGE_LIST_SCROLL, this.closeContextMenu);
    clearTimeout(this.higlightTimeout);
  },
  methods: {
    hasMediaAttachment(type) {
      if (this.hasAttachments && this.data.attachments.length > 0) {
        const { attachments = [{}] } = this.data;
        const { file_type: fileType } = attachments[0];
        return fileType === type && !this.hasImageError;
      }
      return false;
    },
    handleContextMenuClick() {
      this.showContextMenu = !this.showContextMenu;
    },
    async retrySendMessage() {
      await this.$store.dispatch('sendMessageWithData', this.data);
    },
    onImageLoadError() {
      this.hasImageError = true;
    },
    openContextMenu(e) {
      const shouldSkipContextMenu = e.target?.classList.contains(
        'skip-context-menu'
      );
      if (shouldSkipContextMenu || getSelection().toString()) {
        return;
      }

      e.preventDefault();
      if (e.type === 'contextmenu') {
        this.$track(ACCOUNT_EVENTS.OPEN_MESSAGE_CONTEXT_MENU);
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
<style lang="scss">
.wrap {
  > .bubble {
    min-width: 128px;

    &.is-image,
    &.is-video {
      padding: 0;
      overflow: hidden;

      .image,
      .video {
        max-width: 32rem;
        padding: var(--space-micro);

        > img,
        > video {
          border-radius: var(--border-radius-medium);
        }
        > video {
          height: 100%;
          object-fit: cover;
          width: 100%;
        }
      }
      .video {
        height: 18rem;
      }
    }

    &.is-image.is-text > .message-text__wrap,
    &.is-video.is-text > .message-text__wrap {
      max-width: 32rem;
      padding: var(--space-small) var(--space-normal);
    }

    &.is-private .file.message-text__wrap {
      .file--icon {
        color: var(--w-400);
      }
      .text-block-title {
        color: #3c4858;
      }
      .download.button {
        color: var(--w-400);
      }
    }

    &.is-private.is-text > .message-text__wrap .link {
      color: var(--w-700);
    }
    &.is-private.is-text > .message-text__wrap .prosemirror-mention-node {
      font-weight: var(--font-weight-black);
      background: none;
      border-radius: var(--border-radius-small);
      padding: 0;
      color: var(--color-body);
      text-decoration: underline;
    }

    &.is-from-bot {
      background: var(--v-400);
      .message-text--metadata .time {
        color: var(--v-50);
      }
      &.is-private .message-text--metadata .time {
        color: var(--s-400);
      }
    }

    &.is-failed {
      background: var(--r-200);

      .message-text--metadata .time {
        color: var(--r-50);
      }
    }
  }

  &.is-pending {
    position: relative;
    opacity: 0.8;

    .spinner {
      position: absolute;
      bottom: var(--space-smaller);
      right: var(--space-smaller);
    }

    > .is-image.is-text.bubble > .message-text__wrap {
      padding: 0;
    }
  }
}

.wrap.is-email {
  --bubble-max-width: 84% !important;
}

.sender--info {
  align-items: center;
  color: var(--b-700);
  display: inline-flex;
  padding: var(--space-smaller) 0;

  .sender--available-name {
    font-size: var(--font-size-mini);
    margin-left: var(--space-smaller);
  }
}

.message-failed--alert {
  color: var(--r-900);
  flex-grow: 1;
  text-align: right;
  margin-top: var(--space-smaller) var(--space-smaller) 0 0;
}

li.left,
li.right {
  display: flex;
  align-items: flex-end;
}

li.left.has-tweet-menu .context-menu {
  margin-bottom: var(--space-medium);
}

li.has-bg {
  background: var(--w-75);
}

li.right .context-menu-wrap {
  margin-left: auto;
}

li.right {
  flex-direction: row-reverse;
  justify-content: flex-end;

  .wrap.is-pending {
    margin-left: auto;
  }

  .wrap.is-failed {
    display: flex;
    flex-direction: row-reverse;
    align-items: flex-end;
    margin-left: auto;
  }
}

.has-context-menu {
  background: var(--color-background);
}

.context-menu {
  position: relative;
}

/* Markdown styling */

.bubble .text-content {
  p code {
    background-color: var(--s-75);
    display: inline-block;
    line-height: 1;

    border-radius: var(--border-radius-small);
    padding: var(--space-smaller);
  }

  pre {
    background-color: var(--s-75);
    border-color: var(--s-75);
    color: var(--s-800);
    border-radius: var(--border-radius-normal);
    padding: var(--space-small);
    margin-top: var(--space-smaller);
    margin-bottom: var(--space-small);
    display: block;
    line-height: 1.7;
    white-space: pre-wrap;

    code {
      background-color: transparent;
      color: var(--s-800);
      padding: 0;
    }
  }

  blockquote {
    border-left: var(--space-micro) solid var(--s-75);
    color: var(--s-800);
    padding: var(--space-smaller) var(--space-small);
    margin: var(--space-smaller) 0;
    padding: var(--space-small) var(--space-small) 0 var(--space-normal);
  }
}

.right .bubble .text-content {
  p code {
    background-color: var(--w-600);
    color: var(--white);
  }

  pre {
    background-color: var(--w-800);
    border-color: var(--w-700);
    color: var(--white);

    code {
      background-color: transparent;
      color: var(--white);
    }
  }

  blockquote {
    border-left: var(--space-micro) solid var(--w-400);
    color: var(--white);

    p {
      color: var(--w-75);
    }
  }
}
</style>
