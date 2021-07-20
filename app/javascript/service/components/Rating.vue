<template>
  <div class="customer-satisfcation">
    <h6 class="title">
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
</template>

<script>
import { CSAT_RATINGS } from 'shared/constants/messages';

export default {
  props: {
    messageContentAttributes: {
      type: Object,
      default: () => {},
    },
    messageId: {
      type: Number,
      // required: true,
      default: 334,
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
      // this.isUpdating = true;
      // try {
      //   await this.$store.dispatch('message/update', {
      //     submittedValues: {
      //       csat_survey_response: {
      //         rating: this.selectedRating,
      //         feedback_message: this.feedback,
      //       },
      //     },
      //     messageId: this.messageId,
      //   });
      // } catch (error) {
      //   // Ignore error
      // } finally {
      //   this.isUpdating = false;
      // }
    },
    selectRating(rating) {
      this.selectedRating = rating.value;
      this.onSubmit();
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~service/assets/scss/variables.scss';
@import '~service/assets/scss/mixins.scss';

.customer-satisfcation {
  .title {
    font-size: $font-size-default;
    font-weight: $font-weight-medium;
    padding: $space-two $space-one 0;
    text-align: center;
  }

  .ratings {
    display: flex;
    justify-content: space-between;
    padding: $space-two $zero;

    .emoji-button {
      box-shadow: none;
      filter: grayscale(100%);
      font-size: $font-size-mega;
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
}
</style>
