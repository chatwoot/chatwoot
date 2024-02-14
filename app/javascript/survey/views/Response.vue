<template>
    <div class="w-full my-0 m-auto px-12 pt-12 pb-6">
      <label
        class="text-base font-medium text-black-800 mb-4"
      >
        {{ surveyQuestion }}
      </label>
      <rating
        :selected-rating="selectedRating"
        @selectRating="selectRating"
      />
      <banner
        v-if="shouldShowBanner"
        :show-success="shouldShowSuccessMesage"
        :show-error="shouldShowErrorMesage"
        :message="message"
      />
      <feedback
        v-if="enableFeedbackForm"
        :is-updating="isUpdating"
        :is-button-disabled="isButtonDisabled"
        :selected-rating="selectedRating"
        @sendFeedback="sendFeedback"
      />
    </div>
</template>

<script>
import Spinner from 'shared/components/Spinner.vue';
import Rating from 'survey/components/Rating.vue';
import Feedback from 'survey/components/Feedback.vue';
import Banner from 'survey/components/Banner.vue';
import configMixin from 'shared/mixins/configMixin';
import { getSurveyDetails, updateSurvey } from 'survey/api/survey';
import alertMixin from 'shared/mixins/alertMixin';

export default {
  name: 'Response',
  components: {
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
    survey: {
      type: Object,
      default: () => {},
    },
    index: {
      type: Number,
      default: 0
    }
  },

  data() {
    return {
      messageId: null,
      surveyQuestion: null,
      surveyDetails: null,
      errorMessage: null,
      selectedRating: null,
      feedbackMessage: '',
      isUpdating: false,
      logo: '',
      inboxName: '',
      arrayParams: {}
    };
  },
  computed: {
    surveyId() {
      const pageURL = window.location.pathname;
      return pageURL.substring(pageURL.lastIndexOf('/') + 1);
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
      return !this.isFeedbackSubmitted && this.isRatingSubmitted && this.firstSurvey;
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
    urlParam() {
      const queryString = window.location.search;
      return new URLSearchParams(queryString);
    },
    paramsMessageId() {
      return this.urlParam.get('message_id');
    },
    paramsRating() {
      return this.urlParam.get('rating');
    },
    firstSurvey() {
      return this.index == 0;
    }
  },
  async mounted() {
    this.getSurveyDetails();
    this.syncPresubmittedRating();
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
      try {
        this.messageId = this.survey.id
        this.surveyQuestion = this.survey.content;
        this.logo = this.survey.inbox_avatar_url;
        this.inboxName = this.survey.inbox_name;
        this.surveyDetails = this.survey?.csat_survey_response;
        this.selectedRating = this.surveyDetails?.rating;
        this.feedbackMessage = this.surveyDetails?.feedback_message || '';
        this.setLocale(this.survey.locale);
      } catch (error) {
        const errorMessage = error?.response?.data?.message;
        this.errorMessage = errorMessage || this.$t('SURVEY.API.ERROR_MESSAGE');
      }
    },
    syncPresubmittedRating(){
      if (this.paramsMessageId != this.messageId) {
        return;
      }

      this.selectRating(parseInt(this.paramsRating));
    },
    async updateSurveyDetails() {
      this.isUpdating = true;
      try {
        const data = {
          message_id: this.messageId,
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
        const errorMessage = error?.response?.data?.error;
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
