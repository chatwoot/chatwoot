<template>
  <div>
    <div v-for="message in csatMessages"
          :key="message.id">
      <div v-if="!isEmail(message)" v-dompurify-html="formatCsat(message)" class="text-content" />
      <letter
        v-else
        class="text-content bg-white dark:bg-white text-slate-900 dark:text-slate-900 p-2 rounded-[4px]"
        :html="formatCsat(message)"
      />

      <br>
    </div>
  </div>
</template>

<script>
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
import { generateBotMessageContent } from './../helpers/botMessageContentHelper';
import Letter from 'vue-letter';
import { CONTENT_TYPES } from 'shared/constants/contentType';

export default {
  mixins: [messageFormatterMixin],
  props: {
    csatMessages: {
      type: Array,
      default: [],
    },
  },
  methods: {
    formatCsat(csat){
      const botMessageContent = generateBotMessageContent(
        csat.content_type,
        csat.content_attributes,
        {
          noResponseText: this.$t('CONVERSATION.NO_RESPONSE'),
          csat: {
            ratingTitle: this.$t('CONVERSATION.RATING_TITLE'),
            feedbackTitle: this.$t('CONVERSATION.FEEDBACK_TITLE'),
          },
        }
      );

      return (
        this.formatMessage(
          this.formatted_content(csat.content),
          false,
          false
        ) + botMessageContent
      );
    },
    isEmail(csat){
      return csat.content_type === CONTENT_TYPES.INCOMING_EMAIL;
    },
    formatted_content(content){
      var urlRegex = /(https?:\/\/[^\s]+)/g;

      // Replace URLs with an empty string
      var stringWithoutUrls = content.replace(urlRegex, '');

      return stringWithoutUrls;
    }
  },
};
</script>