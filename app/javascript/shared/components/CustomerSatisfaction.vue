<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import { CSAT_RATINGS, CSAT_DISPLAY_TYPES } from 'shared/constants/messages';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import StarRating from 'shared/components/StarRating.vue';
import { getContrastingTextColor } from '@chatwoot/utils';

export default {
  components: {
    Spinner,
    FluentIcon,
    StarRating,
  },
  props: {
    messageContentAttributes: {
      type: Object,
      default: () => {},
    },
    messageId: {
      type: Number,
      required: true,
    },
    displayType: {
      type: String,
      default: CSAT_DISPLAY_TYPES.EMOJI,
    },
    message: {
      type: String,
      default: '',
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
    ...mapGetters({ widgetColor: 'appConfig/getWidgetColor' }),
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
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    title() {
      return this.isRatingSubmitted
        ? this.$t('CSAT.SUBMITTED_TITLE')
        : this.message || this.$t('CSAT.TITLE');
    },
    isEmojiType() {
      return this.displayType === CSAT_DISPLAY_TYPES.EMOJI;
    },
    isStarType() {
      return this.displayType === CSAT_DISPLAY_TYPES.STAR;
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
    buttonClass(rating) {
      return [
        { selected: rating.value === this.selectedRating },
        { disabled: this.isRatingSubmitted },
        { hover: this.isRatingSubmitted },
        'emoji-button',
      ];
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
    },

    selectRating(rating) {
      this.selectedRating = rating.value;
      this.onSubmit();
    },
    selectStarRating(value) {
      this.selectedRating = value;
      this.onSubmit();
    },
  },
};
</script>

<template>
  <div
    class="customer-satisfaction w-full bg-n-background dark:bg-n-solid-3 shadow-[0_0.25rem_6px_rgba(50,50,93,0.08),0_1px_3px_rgba(0,0,0,0.05)] ltr:rounded-bl-[0.25rem] rtl:rounded-br-[0.25rem] rounded-lg inline-block leading-[1.5] mt-1 border-t-2 border-t-n-brand border-solid"
    :style="{ borderColor: widgetColor }"
  >
    <h6 class="text-n-slate-12 text-sm font-medium pt-5 px-2.5 text-center">
      {{ title }}
    </h6>
    <div v-if="isEmojiType" class="ratings flex justify-around py-5 px-4">
      <button
        v-for="rating in ratings"
        :key="rating.key"
        :class="buttonClass(rating)"
        @click="selectRating(rating)"
      >
        {{ rating.emoji }}
      </button>
    </div>
    <StarRating
      v-else-if="isStarType"
      :selected-rating="selectedRating"
      :is-disabled="isRatingSubmitted"
      @select-rating="selectStarRating"
    />
    <form
      v-if="!isFeedbackSubmitted"
      class="feedback-form flex"
      @submit.prevent="onSubmit()"
    >
      <input
        v-model="feedback"
        :placeholder="$t('CSAT.PLACEHOLDER')"
        @keydown.enter="onSubmit"
      />
      <button
        class="button small"
        :disabled="isButtonDisabled"
        :style="{
          background: widgetColor,
          borderColor: widgetColor,
          color: textColor,
        }"
      >
        <Spinner v-if="isUpdating && feedback" />
        <FluentIcon v-else icon="chevron-right" />
      </button>
    </form>
  </div>
</template>

<style lang="scss" scoped>
.customer-satisfaction {
  .ratings {
    .emoji-button {
      @apply shadow-none grayscale text-2xl outline-none transition-all duration-200;

      &.selected,
      &:hover,
      &:focus,
      &:active {
        @apply grayscale-0 scale-[1.32];
      }

      &.disabled {
        @apply cursor-not-allowed opacity-50 pointer-events-none;
      }
    }
  }

  .feedback-form {
    input {
      @apply h-10 dark:bg-n-alpha-black1 rtl:rounded-tl-[0] rtl:rounded-tr-[0] ltr:rounded-tr-[0] ltr:rounded-tl-[0] rtl:rounded-bl-[0] ltr:rounded-br-[0] ltr:rounded-bl-[0.25rem] rtl:rounded-br-[0.25rem] rounded-lg p-2.5 w-full focus:ring-0 focus:outline-n-brand;

      &::placeholder {
        @apply text-n-slate-10;
      }
    }

    .button {
      @apply rtl:rounded-tr-[0] rtl:rounded-tl-[0] appearance-none ltr:rounded-tl-[0] ltr:rounded-tr-[0] rtl:rounded-br-[0] ltr:rounded-bl-[0] rounded-lg h-auto ltr:-ml-px rtl:-mr-px text-xl;

      .spinner {
        display: block;
        padding: 0;
        height: auto;
        width: auto;
      }
    }
  }
}
</style>
