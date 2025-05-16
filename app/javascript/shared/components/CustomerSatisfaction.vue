<template>
  <div
    v-if="!isRatingSubmitted"
    class="customer-satisfaction w-full flex flex-col justify-center items-center shadow-[0px_0px_2px_rgba(0,0,0,0.05)] py-4 px-6 bg-[#FAFAFA] gap-2 border-t border-solid border-[#d9d9d9]"
    :class="$dm('bg-[#FAFAFA]', 'dark:bg-slate-700')"
  >
    <h6
      class="text-sm font-medium leading-5 text-center"
      :class="$dm('text-slate-900', 'dark:text-slate-50')"
    >
      {{ title }}
    </h6>
    <div class="ratings">
      <button
        v-for="rating in ratings"
        :key="rating.key"
        :class="buttonClass(rating)"
        @click="selectRating(rating)"
      >
        {{ rating.emoji }}
      </button>
    </div>
  </div>
  <div
    v-else
    class="customer-satisfaction w-full shadow-[0px_0px_2px_rgba(0,0,0,0.05)] py-3 px-4 bg-[#FAFAFA] gap-2 min-h-[7.125rem] border-t border-solid border-[#d9d9d9]"
    :class="$dm('bg-[#FAFAFA]', 'dark:bg-slate-700')"
  >
    <div
      v-if="channelConfig.backPopulateConversation"
      class="flex flex-col justify-between w-full gap-2"
    >
      <h6
        class="text-sm font-medium leading-5 text-center"
        :class="$dm('text-slate-900', 'dark:text-slate-50')"
      >
        {{ 'Continue to Chat' }}
      </h6>
      <chat-input-wrap :on-send-message="handleSendMessage" />
    </div>
    <div v-else class="flex flex-col gap-3 justify-center items-center">
      <h6
        class="text-sm font-medium leading-5 text-center"
        :class="$dm('text-slate-900', 'dark:text-slate-50')"
      >
        {{
          isUpdating ? 'Creating new conversation' : 'Create new conversation'
        }}
      </h6>
      <button
        v-if="!isUpdating"
        class="bg-[#F0F0F0] border border-solid border-[#E6E6E6] w-auto flex justify-center items-center gap-2 text-xs py-2 px-3 rounded-md shadow-[0px_1px_0px_0px #0000000D] transition-all duration-300 create-chat-button"
        @click.prevent="handleCreateConversation"
      >
        Create New Chat
      </button>
      <img
        v-if="isUpdating"
        class="h-7"
        src="~widget/assets/images/typing.gif"
        alt="Spinner Message"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters, mapActions } from 'vuex';
// import Spinner from 'shared/components/Spinner.vue';
import { CSAT_RATINGS } from 'shared/constants/messages';
// import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import darkModeMixin from 'widget/mixins/darkModeMixin';
import configMixin from 'widget/mixins/configMixin';
import { getContrastingTextColor } from '@chatwoot/utils';
import routerMixin from 'widget/mixins/routerMixin';
import ChatInputWrap from 'widget/components/ChatInputWrap.vue';

export default {
  components: {
    ChatInputWrap,
  },
  mixins: [darkModeMixin, routerMixin, configMixin],
  props: {
    messageContentAttributes: {
      type: Object,
      default: () => {},
    },
    messageId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      email: '',
      ratings: CSAT_RATINGS,
      selectedRating: null,
      isUpdating: false,
      feedback: '',
    };
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
      conversationSize: 'conversation/getConversationSize',
    }),
    isRatingSubmitted() {
      return this.messageContentAttributes?.csat_survey_response?.rating;
    },
    isFeedbackSubmitted() {
      return this.messageContentAttributes?.csat_survey_response
        ?.feedback_message;
    },
    isButtonDisabled() {
      return !(this.selectedRating && this.feedback);
    },
    inputColor() {
      return `${this.$dm('bg-white', 'dark:bg-slate-600')}
        ${this.$dm('text-black-900', 'dark:text-slate-50')}`;
    },
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    title() {
      return this.isRatingSubmitted
        ? this.$t('CSAT.SUBMITTED_TITLE')
        : 'How was your experience?';
    },
  },

  mounted() {
    if (this.isRatingSubmitted) {
      const {
        csat_survey_response: { rating, feedback_message },
      } = this.messageContentAttributes;
      this.selectedRating = rating;
      this.feedback = feedback_message;
    }
  },

  methods: {
    ...mapActions('conversation', ['createNewConversation', 'sendMessage']),
    ...mapActions('conversationAttributes', ['getAttributes']),
    buttonClass(rating) {
      return [
        { selected: rating.value === this.selectedRating },
        { disabled: this.isRatingSubmitted },
        { hover: this.isRatingSubmitted },
        'emoji-button',
      ];
    },
    async handleSendMessage(content) {
      await this.sendMessage({
        content,
      });
      this.handleCreateConversation();
    },
    async handleCreateConversation() {
      this.isUpdating = true;
      try {
        await this.createNewConversation();
        if (!this.channelConfig.backPopulateConversation) {
          this.replaceRoute('home');
        }
        if (this.conversationSize === 0) {
          this.getAttributes();
        }
      } catch (error) {
        // eslint-disable-next-line no-console
        console.error(error);
      } finally {
        this.isUpdating = false;
      }
    },
    async onSubmit() {
      this.isUpdating = true;
      try {
        await this.$store.dispatch('message/update', {
          submittedValues: {
            csat_survey_response: {
              rating: this.selectedRating,
              feedback_message: this.feedback,
            },
          },
          messageId: this.messageId,
        });
      } catch (error) {
        // Ignore error
      } finally {
        this.isUpdating = false;
      }
      // this.handleCreateConversation();
    },
    selectRating(rating) {
      this.selectedRating = rating.value;
      this.onSubmit();
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';
@import '~widget/assets/scss/mixins.scss';

.customer-satisfaction {
  z-index: 100;
  color: $color-body;
  line-height: 1.5;
  position: fixed;
  bottom: 37px;
  left: 0;
  right: 0;

  .title {
    font-size: $font-size-default;
    font-weight: $font-weight-medium;
    padding: $space-two $space-one 0;
    text-align: center;
  }

  .ratings {
    display: flex;
    gap: 20px;

    .emoji-button {
      box-shadow: none;
      font-size: $font-size-big;
      outline: none;
      font-size: 36px;
      transition: all 0.2s ease;
      transform-origin: center;

      &.selected,
      &:hover,
      &:focus,
      &:active {
        transform: scale(1.32);
      }

      &.disabled {
        cursor: default;
        opacity: 0.5;
        pointer-events: none;
      }
    }
  }
}

.create-chat-button:hover {
  background-color: var(--widget-color);
  color: var(--text-color) !important;
  border: var(--widget-color) !important;
}

.create-chat-button:hover svg {
  color: var(--text-color) !important;
}

@media (max-width: 768px) {
  .ratings {
    gap: 8px;
  }
}
</style>
