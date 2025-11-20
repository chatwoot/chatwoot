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
    <div v-if="isYesNoFormat" class="yes-no-buttons flex gap-3">
      <button
        v-for="option in yesNoOptions"
        :key="option.key"
        :class="yesNoButtonClass(option)"
        @click="selectRating(option)"
      >
        {{ $t(option.translationKey) }}
      </button>
    </div>
    <div v-else class="ratings">
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
      :class="{
        'items-center': isUpdating,
      }"
    >
      <h6
        class="text-sm font-medium leading-5 text-center"
        :class="$dm('text-slate-900', 'dark:text-slate-50')"
      >
        {{ 'Continue to Chat' }}
      </h6>
      <chat-input-wrap
        v-if="!isUpdating && !isCreatingNewConversation"
        :on-send-message="handleSendMessage"
      />
      <img
        v-else
        class="h-7"
        src="~widget/assets/images/typing.gif"
        alt="Spinner Message"
      />
    </div>
    <div v-else class="flex flex-col gap-3 justify-center items-center">
      <h6
        class="text-sm font-medium leading-5 text-center"
        :class="$dm('text-slate-900', 'dark:text-slate-50')"
      >
        {{ 'Creating new conversation' }}
      </h6>
      <img
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
import {
  CSAT_RATINGS,
  CSAT_YES_NO_OPTIONS,
  CSAT_FORMATS,
} from 'shared/constants/messages';
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
      yesNoOptions: CSAT_YES_NO_OPTIONS,
      selectedRating: null,
      isUpdating: false,
      feedback: '',
    };
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
      conversationSize: 'conversation/getConversationSize',
      isCreatingNewConversation: 'conversation/isCreatingNewConversation',
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
      if (this.isRatingSubmitted) {
        return this.$t('CSAT.SUBMITTED_TITLE');
      }
      // Use custom question text if provided, otherwise use default
      if (this.isYesNoFormat && this.messageContentAttributes?.question_text) {
        return this.messageContentAttributes.question_text;
      }
      return 'How was your experience?';
    },
    isYesNoFormat() {
      return this.messageContentAttributes?.csat_format === CSAT_FORMATS.YES_NO;
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
    yesNoButtonClass(option) {
      const isSelected = option.value === this.selectedRating;
      return [
        'yes-no-button',
        'px-6 py-2 rounded-lg font-medium transition-all',
        option.key, // Add key class for styling (yes/no)
        {
          'bg-white dark:bg-slate-600 border-2': !isSelected,
          'shadow-md transform scale-105': isSelected,
          'hover:shadow-lg hover:transform hover:scale-105':
            !this.isRatingSubmitted,
          'cursor-pointer': !this.isRatingSubmitted,
          'cursor-default opacity-60': this.isRatingSubmitted,
        },
      ];
    },
    async handleSendMessage(content) {
      this.handleCreateConversation(content);
    },
    async handleCreateConversation(content = '') {
      this.isUpdating = true;
      try {
        await this.createNewConversation(content);
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
      if (!this.channelConfig.backPopulateConversation) {
        this.handleCreateConversation('');
      }
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

  .yes-no-buttons {
    .yes-no-button {
      min-width: 100px;
      border-width: 2px;
      border-style: solid;

      &.yes {
        border-color: #44ce4b;
        color: #44ce4b;

        &.shadow-md {
          background-color: #44ce4b;
          color: white;
        }
      }

      &.no {
        border-color: #fdad2a;
        color: #fdad2a;

        &.shadow-md {
          background-color: #fdad2a;
          color: white;
        }
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
