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
    <form
      v-if="!isCSATSubmitted"
      class="feedback-form"
      @submit.prevent="onSubmit()"
    >
      <input
        v-model="feedback"
        class="form-input"
        :placeholder="$t('CSAT.PLACEHOLDER')"
        @keyup.enter="onSubmit"
      />
      <button
        class="button"
        :disabled="isButtonDisabled"
        :style="{ background: widgetColor, borderColor: widgetColor }"
      >
        <i v-if="!isUpdating" class="ion-ios-arrow-forward" />
        <spinner v-else />
      </button>
    </form>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import Spinner from 'shared/components/Spinner';
import { CSAT_RATINGS } from 'shared/constants/messages';

export default {
  components: {
    Spinner,
  },
  props: {
    messageContentAttributes: {
      type: Object,
      default: () => {},
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
    }),
    isCSATSubmitted() {
      return (
        this.messageContentAttributes &&
        this.messageContentAttributes.csat_survey_response
      );
    },
    isButtonDisabled() {
      return !(this.selectedRating && this.feedback);
    },
    title() {
      return this.isCSATSubmitted
        ? this.$t('CSAT.SUBMITTED_TITLE')
        : this.$t('CSAT.TITLE');
    },
  },

  mounted() {
    if (this.isCSATSubmitted) {
      const {
        csat_survey_response: { rating },
      } = this.messageContentAttributes;
      this.selectedRating = rating;
    }
  },

  methods: {
    buttonClass(rating) {
      return [
        { selected: rating.value === this.selectedRating },
        { disabled: this.isCSATSubmitted },
        { hover: this.isCSATSubmitted },
        'emoji-button',
      ];
    },
    onSubmit() {
      this.$emit('submit', {
        rating: this.selectedRating,
        feedback: this.feedback,
      });
    },
    selectRating(rating) {
      this.selectedRating = rating.value;
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';
@import '~widget/assets/scss/mixins.scss';

.customer-satisfcation {
  @include light-shadow;

  background: $color-white;
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
</style>
