<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner.vue';
import { CSAT_RATINGS } from 'shared/constants/messages';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { useDarkMode } from 'widget/composables/useDarkMode';
import { getContrastingTextColor } from '@chatwoot/utils';

export default {
  components: {
    Spinner,
    FluentIcon,
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
  },
  setup() {
    const { getThemeClass } = useDarkMode();
    return { getThemeClass };
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
    inputColor() {
      return `${this.getThemeClass('bg-white', 'dark:bg-slate-600')}
        ${this.getThemeClass('text-black-900', 'dark:text-slate-50')}`;
    },
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    title() {
      return this.isRatingSubmitted
        ? this.$t('CSAT.SUBMITTED_TITLE')
        : this.$t('CSAT.TITLE');
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
  },
};
</script>

<template>
  <div
    class="customer-satisfaction"
    :class="getThemeClass('bg-white', 'dark:bg-slate-700')"
    :style="{ borderColor: widgetColor }"
  >
    <h6
      class="title"
      :class="getThemeClass('text-slate-900', 'dark:text-slate-50')"
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
    <form
      v-if="!isFeedbackSubmitted"
      class="feedback-form"
      @submit.prevent="onSubmit()"
    >
      <input
        v-model="feedback"
        class="form-input"
        :class="inputColor"
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
@import 'widget/assets/scss/variables.scss';
@import 'widget/assets/scss/mixins.scss';

.customer-satisfaction {
  @include light-shadow;

  border-bottom-left-radius: $space-smaller;
  border-radius: $space-small;
  border-top: $space-micro solid $color-woot;
  color: $color-body;
  display: inline-block;
  line-height: 1.5;
  margin-top: $space-smaller;
  width: 80%;

  .title {
    font-size: $font-size-default;
    font-weight: $font-weight-medium;
    padding: $space-two $space-one 0;
    text-align: center;
  }

  .ratings {
    display: flex;
    justify-content: space-around;
    padding: $space-two $space-normal;

    .emoji-button {
      box-shadow: none;
      filter: grayscale(100%);
      font-size: $font-size-big;
      outline: none;

      &.selected,
      &:hover,
      &:focus,
      &:active {
        filter: grayscale(0%);
        transform: scale(1.32);
      }

      &.disabled {
        cursor: default;
        opacity: 0.5;
        pointer-events: none;
      }
    }
  }

  .feedback-form {
    display: flex;

    input {
      border-bottom-right-radius: 0;
      border-top-right-radius: 0;
      border-bottom-left-radius: $space-small;
      border: 0;
      border-top: 1px solid $color-border;
      padding: $space-one;
      width: 100%;

      &::placeholder {
        color: $color-light-gray;
      }
    }

    .button {
      appearance: none;
      border-bottom-left-radius: 0;
      border-top-left-radius: 0;
      border-bottom-right-radius: $space-small;
      font-size: $font-size-large;
      height: auto;
      margin-left: -1px;

      .spinner {
        display: block;
        padding: 0;
        height: auto;
        width: auto;
      }
    }
  }
}

@media (prefers-color-scheme: dark) {
  .customer-satisfaction .feedback-form input {
    border-top: 1px solid var(--b-500);
  }
}
</style>
