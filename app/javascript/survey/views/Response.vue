<template>
  <div
    v-if="isLoading"
    class="flex flex-1 items-center h-full bg-black-25 justify-center"
  >
    <spinner size="" />
  </div>
  <div
    v-else
    class="w-full h-full flex flex-col flex-no-wrap overflow-hidden bg-white"
  >
    <div class="flex flex-1 overflow-auto">
      <div class="max-w-screen-sm w-full my-0 m-auto px-8 py-12">
        <img :src="logo" alt="Chatwoot logo" class="logo" @error="imgUrlAlt" />
        <p class="text-black-700 text-lg leading-relaxed mt-4 mb-4">
          {{ surveyDescription }}
        </p>
        <banner
          v-if="shouldShowBanner"
          :show-success="shouldShowSuccessMesage"
          :show-error="shouldShowErrorMesage"
          :message="message"
        />
        <label
          v-if="!isRatingSubmitted"
          class="text-base font-medium text-black-800 mt-4 mb-4"
        >
          {{ $t('SURVEY.RATING.LABEL') }}
        </label>
        <rating
          :selected-rating="selectedRating"
          @selectRating="selectRating"
        />
        <feedback
          v-if="enableFeedbackForm"
          :is-updating="isUpdating"
          :is-button-disabled="isButtonDisabled"
          :selected-rating="selectedRating"
          @sendFeedback="sendFeedback"
        />
      </div>
    </div>
    <div class="footer-wrap flex-shrink-0 w-full flex flex-col relative">
      <branding></branding>
    </div>
  </div>
</template>

<script>
import Branding from 'shared/components/Branding';
import Spinner from 'shared/components/Spinner';
import Rating from 'survey/components/Rating';
import Feedback from 'survey/components/Feedback';
import Banner from 'survey/components/Banner';
import configMixin from 'shared/mixins/configMixin';
import { getSurveyDetails, updateSurvey } from 'survey/api/survey';
import alertMixin from 'shared/mixins/alertMixin';
const BRAND_LOGO = '/brand-assets/logo.svg';
export default {
  name: 'Home',
  components: {
    Branding,
    Rating,
    Spinner,
    Banner,
    Feedback,
  },
  mixins: [alertMixin, configMixin],
  props: {
    showHomePage: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      surveyDetails: null,
      isLoading: false,
      errorMessage: null,
      selectedRating: null,
      feedbackMessage: '',
      isUpdating: false,
      logo: '',
    };
  },
  computed: {
    surveyId() {
      const pageURL = window.location.href;
      return pageURL.substr(pageURL.lastIndexOf('/') + 1);
    },
    isRatingSubmitted() {
      return this.surveyDetails && this.surveyDetails.rating;
    },
    isFeedbackSubmitted() {
      return this.surveyDetails && this.surveyDetails.feedback_message;
    },
    isButtonDisabled() {
      return !(this.selectedRating && this.feedback);
    },
    shouldShowBanner() {
      return this.isRatingSubmitted || this.errorMessage;
    },
    enableFeedbackForm() {
      return !this.isFeedbackSubmitted && this.isRatingSubmitted;
    },
    shouldShowErrorMesage() {
      return !!this.errorMessage;
    },
    shouldShowSuccessMesage() {
      return !!this.isRatingSubmitted;
    },
    message() {
      if (this.errorMessage) {
        return this.errorMessage;
      }
      return this.$t('SURVEY.RATING.SUCCESS_MESSAGE');
    },
    surveyDescription() {
      return this.isRatingSubmitted ? '' : this.$t('SURVEY.DESCRIPTION');
    },
  },
  async mounted() {
    this.getSurveyDetails();
  },
  methods: {
    selectRating(rating) {
      this.selectedRating = rating;
      this.updateSurveyDetails();
    },
    sendFeedback(message) {
      this.feedbackMessage = message;
      this.updateSurveyDetails();
    },
    imgUrlAlt() {
      this.logo = BRAND_LOGO;
    },
    async getSurveyDetails() {
      this.isLoading = true;
      try {
        const result = await getSurveyDetails({ uuid: this.surveyId });
        this.logo = result.data.inbox_avatar_url;
        this.surveyDetails = result?.data?.csat_survey_response;
        this.selectedRating = this.surveyDetails?.rating;
        this.feedbackMessage = this.surveyDetails?.feedback_message || '';
      } catch (error) {
        const errorMessage = error?.response?.data?.message;
        this.errorMessage = errorMessage || this.$t('SURVEY.API.ERROR_MESSAGE');
      } finally {
        this.isLoading = false;
      }
    },
    async updateSurveyDetails() {
      this.isUpdating = true;
      try {
        const data = {
          message: {
            submitted_values: {
              csat_survey_response: {
                rating: this.selectedRating,
                feedback_message: this.feedbackMessage,
              },
            },
          },
        };
        await updateSurvey({
          uuid: this.surveyId,
          data,
        });
        this.surveyDetails = {
          rating: this.selectedRating,
          feedback_message: this.feedbackMessage,
        };
      } catch (error) {
        const errorMessage = error?.response?.data?.message;
        this.errorMessage = errorMessage || this.$t('SURVEY.API.ERROR_MESSAGE');
      } finally {
        this.isUpdating = false;
      }
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';
.logo {
  max-height: $space-large;
}
</style>
