<template>
  <li v-if="isTemplateMessage" :class="alignBubble">
    <div :class="wrapClass">
      <div v-tooltip.top-start="sentByMessage" :class="bubbleClass">
        <div v-if="isTemplateEmail">
          <span v-html="formatMessage(data.content)"></span>
          <email-input
            :message-id="data.id"
            :read-only="true"
            :message-content-attributes="data.content_attributes"
          />
        </div>
        <div v-if="isOptions">
          <chat-options
            :title="data.message"
            :read-only="true"
            :options="data.content_attributes.items"
            :hide-fields="false"
          />
        </div>
        <div v-if="isForm">
          <span v-html="formatMessage(data.content)"></span>
          <chat-form
            :items="data.content_attributes.items"
            :read-only="true"
            :button-label="data.content_attributes.button_label"
            :submitted-values="data.content_attributes.submitted_values"
          />
        </div>
        <div v-if="isCards">
          <span v-html="formatMessage(data.content)"></span>
          <chat-card
            v-for="item in data.content_attributes.items"
            :key="item.title"
            :media-url="item.media_url"
            :title="item.title"
            :description="item.description"
            :actions="item.actions"
            :read-only="true"
          >
          </chat-card>
        </div>
        <div v-if="isArticle">
          <span v-html="formatMessage(data.content)"></span>
          <chat-article :items="data.content_attributes.items"></chat-article>
        </div>
      </div>
    </div>
  </li>
  <li v-else-if="hasAttachments || data.content" :class="alignBubble">
    <div :class="wrapClass">
      <p v-tooltip.top-start="sentByMessage" :class="bubbleClass">
        <bubble-text
          v-if="data.content"
          :message="message"
          :readable-time="readableTime"
        />
        <span v-if="hasAttachments">
          <span v-for="attachment in data.attachments" :key="attachment.id">
            <bubble-image
              v-if="attachment.file_type === 'image'"
              :url="attachment.data_url"
              :readable-time="readableTime"
            />
            <bubble-file
              v-if="attachment.file_type !== 'image'"
              :url="attachment.data_url"
              :readable-time="readableTime"
            />
          </span>
        </span>
        <i
          v-if="isPrivate"
          v-tooltip.top-start="toolTipMessage"
          class="icon ion-android-lock"
          @mouseenter="isHovered = true"
          @mouseleave="isHovered = false"
        />
      </p>
    </div>
    <!-- <img
      src="https://randomuser.me/api/portraits/women/94.jpg"
      class="sender--thumbnail"
    /> -->
  </li>
</template>
<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import getEmojiSVG from '../emoji/utils';
import timeMixin from '../../../mixins/time';
import BubbleText from './bubble/Text';
import BubbleImage from './bubble/Image';
import BubbleFile from './bubble/File';
import ChatCard from 'shared/components/messageTemplates/ChatCard';
import ChatForm from 'shared/components/messageTemplates/ChatForm';
import ChatOptions from 'shared/components/messageTemplates/ChatOptions';
import ChatArticle from 'shared/components/messageTemplates/Article';
import EmailInput from 'shared/components/messageTemplates/EmailInput';

export default {
  components: {
    BubbleText,
    BubbleImage,
    BubbleFile,
    ChatArticle,
    ChatCard,
    ChatForm,
    ChatOptions,
    EmailInput,
  },
  mixins: [timeMixin, messageFormatterMixin],
  props: {
    data: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isHovered: false,
    };
  },
  computed: {
    message() {
      return this.formatMessage(this.data.content);
    },
    alignBubble() {
      if (this.data.message_type === 0) {
        return 'left';
      }
      return 'right';
    },
    readableTime() {
      return this.messageStamp(this.data.created_at);
    },
    isBubble() {
      return [0, 1, 2, 3].includes(this.data.message_type);
    },
    hasAttachments() {
      return !!(this.data.attachments && this.data.attachments.length > 0);
    },
    isTemplate() {
      return this.data.message_type === 3;
    },
    isTemplateEmail() {
      return this.data.content_type === 'input_email';
    },
    isCards() {
      return this.data.content_type === 'cards';
    },
    isOptions() {
      return this.data.content_type === 'input_select';
    },
    isForm() {
      return this.data.content_type === 'form';
    },
    isArticle() {
      return this.data.content_type === 'article';
    },
    isTemplateMessage() {
      return (
        this.data.content_type === 'input_email' ||
        this.data.content_type === 'cards' ||
        this.data.content_type === 'input_select' ||
        this.data.content_type === 'form' ||
        this.data.content_type === 'article'
      );
    },
    hasRecordedResponse() {
      return (
        this.data.content_attributes.submitted_email ||
        (this.data.content_attributes.submitted_values &&
          this.contentType !== 'form')
      );
    },
    hasImageAttachment() {
      if (this.hasAttachments && this.data.attachments.length > 0) {
        const { attachments = [{}] } = this.data;
        const { file_type: fileType } = attachments[0];
        return fileType === 'image';
      }
      return false;
    },
    isPrivate() {
      return this.data.private;
    },
    toolTipMessage() {
      return this.data.private
        ? { content: this.$t('CONVERSATION.VISIBLE_TO_AGENTS'), classes: 'top' }
        : false;
    },
    sentByMessage() {
      const { sender } = this.data;

      return this.data.message_type === 1 && !this.isHovered && sender
        ? {
            content: `Sent by: ${sender.available_name || sender.name}`,
            classes: 'top',
          }
        : false;
    },
    wrapClass() {
      return {
        wrap: this.isBubble,
        'activity-wrap': !this.isBubble,
      };
    },
    bubbleClass() {
      return {
        bubble: this.isBubble,
        'is-private': this.isPrivate,
        'is-image': this.hasImageAttachment,
        'is-template': this.isTemplateMessage,
      };
    },
  },
  methods: {
    getEmojiSVG,
  },
};
</script>
<style lang="scss" scoped>
@import '~dashboard/assets/scss/variables.scss';
.wrap {
  .is-image {
    padding: 0;
    overflow: hidden;
  }

  .is-template {
    background-color: $color-white;
    color: $color-body;
    margin: 0.5rem 0rem;
    border: $color-border 1px solid;
  }

  .image {
    max-width: 32rem;
    padding: 0;
  }
}
</style>
