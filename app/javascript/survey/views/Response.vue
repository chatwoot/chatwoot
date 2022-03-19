<template>
  <div
    v-if="isLoading"
    class="flex flex-1 items-center h-full bg-black-25 justify-center"
  >
    <spinner size="" />
  </div>
  <div
    v-else
    class="w-full h-full flex overflow-auto bg-slate-50 items-center justify-center"
  >
    <div
      class="flex bg-white shadow-lg rounded-lg flex-col w-full lg:w-2/5 h-full lg:h-auto"
    >
      <div class="w-full my-0 m-auto px-12 pt-12 pb-6">
        <img v-if="logo" :src="logo" alt="Chatwoot logo" class="logo mb-6" />
        <p
          v-if="!isRatingSubmitted"
          class="text-black-700 text-lg leading-relaxed mb-8"
        >
          {{ $t('SURVEY.DESCRIPTION', { inboxName }) }}
        </p>
        <banner
          v-if="shouldShowBanner"
          :show-success="shouldShowSuccessMesage"
          :show-error="shouldShowErrorMesage"
          :message="message"
        />
        <label
          v-if="!isRatingSubmitted"
          class="text-base font-medium text-black-800 mb-4"
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
      <div class="mb-3">
        <branding></branding>
      </div>
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

export default {
  name: 'Response',
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
      inboxName: '',
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
    async getSurveyDetails() {
      this.isLoading = true;
      try {
        const result = await getSurveyDetails({ uuid: this.surveyId });
        this.logo = result.data.inbox_avatar_url;
        this.inboxName = result.data.inbox_name;
        this.surveyDetails = result?.data?.csat_survey_response;
        this.selectedRating = this.surveyDetails?.rating;
        this.feedbackMessage = this.surveyDetails?.feedback_message || '';
        this.setLocale(result.data.locale);
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
    setLocale(locale) {
      this.$root.$i18n.locale = locale || 'en';
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.logo {
  max-height: $space-larger;
}
</style>
