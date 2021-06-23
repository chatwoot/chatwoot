<template>
  <div class="customer-satisfcation">
    <div class="title">
      {{ $t('CSAT.TITLE') }}
    </div>
    <div class="ratings">
      <button
        v-for="rating in ratings"
        :key="rating.key"
        class="emoji-button"
        :class="{ selected: rating.key === selectedRating }"
        @click="selectRating(rating)"
      >
        {{ rating.emoji }}
      </button>
    </div>
    <form
      v-if="!hasSubmitted"
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
        :disabled="!selectedRating"
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
  data() {
    return {
      email: '',
      ratings: CSAT_RATINGS,
      selectedRating: null,
      isUpdating: false,
      feedback: '',
      hasSubmitted: false,
    };
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
  },

  methods: {
    onSubmit() {},
    selectRating(rating) {
      this.selectedRating = rating.key;
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
  color: $color-body;
  border-top: $space-micro solid $color-woot;
  border-radius: $space-one;
  display: inline-block;
  line-height: 1.5;
  width: 75%;
  .title {
    font-size: $font-size-default;
    font-weight: $font-weight-medium;
    padding-top: $space-two;
    text-align: center;
  }
  .ratings {
    display: flex;
    justify-content: space-around;
    padding: $space-two $space-normal;

    .emoji-button {
      font-size: $font-size-big;
      outline: none;
      box-shadow: none;
      filter: grayscale(100%);
      &.selected {
        filter: grayscale(0%);
        transform: scale(1.32);
      }
    }
  }
  .feedback-form {
    display: flex;
    input {
      width: 100%;
      border: none;
      border-bottom-right-radius: 0;
      border-top-right-radius: 0;
      padding: $space-one;
      border-top: 1px solid $color-border;
    }

    .button {
      border-bottom-left-radius: 0;
      border-top-left-radius: 0;
      font-size: $font-size-large;
      height: auto;
      margin-left: -1px;
      appearance: none;
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
