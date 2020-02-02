<template>
  <li v-if="data.attachment || data.content" :class="alignBubble">
    <div :class="wrapClass">
      <p
        v-tooltip.top-start="sentByMessage"
        :class="{ bubble: isBubble, 'is-private': isPrivate }"
      >
        <bubble-image
          v-if="data.attachment && data.attachment.file_type === 'image'"
          :url="data.attachment.data_url"
          :readable-time="readableTime"
        />
        <bubble-audio
          v-if="data.attachment && data.attachment.file_type === 'audio'"
          :url="data.attachment.data_url"
          :readable-time="readableTime"
        />
        <bubble-map
          v-if="data.attachment && data.attachment.file_type === 'location'"
          :lat="data.attachment.coordinates_lat"
          :lng="data.attachment.coordinates_long"
          :label="data.attachment.fallback_title"
          :readable-time="readableTime"
        />
        <i v-if="data.message_type === 2" class="icon ion-person" />
        <bubble-text
          v-if="data.content"
          :message="message"
          :readable-time="readableTime"
        />
        <i
          v-if="isPrivate"
          v-tooltip.top-start="toolTipMessage"
          class="icon ion-android-lock"
          @mouseenter="isHovered = true"
          @mouseleave="isHovered = false"
        />
      </p>
    </div>
    <!-- <img v-if="showSenderData" src="https://chatwoot-staging.s3-us-west-2.amazonaws.com/uploads/avatar/contact/3415/thumb_10418362_10201264050880840_6087258728802054624_n.jpg?X-Amz-Algorithm=AWS4-HMAC-SHA256&amp;X-Amz-Credential=AKIAI3KBM2ES3VRHQHPQ%2F20170422%2Fus-west-2%2Fs3%2Faws4_request&amp;X-Amz-Date=20170422T075421Z&amp;X-Amz-Expires=604800&amp;X-Amz-SignedHeaders=host&amp;X-Amz-Signature=8d5ff60e41415515f59ff682b9a4e4c0574d9d9aabfeff1dc5a51087a9b49e03" class="sender--thumbnail"> -->
  </li>
</template>
<script>
/* eslint-disable no-named-as-default */
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import getEmojiSVG from '../emoji/utils';
import timeMixin from '../../../mixins/time';
import BubbleText from './bubble/Text';
import BubbleImage from './bubble/Image';
import BubbleMap from './bubble/Map';
import BubbleAudio from './bubble/Audio';

export default {
  components: {
    BubbleText,
    BubbleImage,
    BubbleMap,
    BubbleAudio,
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
      return !this.data.message_type ? 'left' : 'right';
    },
    readableTime() {
      return this.messageStamp(this.data.created_at);
    },
    isBubble() {
      return [0, 1, 3].includes(this.data.message_type);
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
      return this.data.message_type === 1 &&
        !this.isHovered &&
        this.data.sender !== undefined
        ? { content: `Sent by: ${this.data.sender.name}`, classes: 'top' }
        : false;
    },
    wrapClass() {
      return {
        wrap: this.isBubble,
        'activity-wrap': !this.isBubble,
      };
    },
  },
  methods: {
    getEmojiSVG,
  },
};
</script>
