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
          v-if="enableBanner"
          :show-success="isRatingSubmitted"
          :show-error="errorMessage"
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
        <label
          v-if="!isFeedbackSubmitted"
          class="text-base font-medium text-black-800"
        >
          {{ $t('SURVEY.FEEDBACK.LABEL') }}
        </label>
        <text-area
          v-if="!isFeedbackSubmitted"
          v-model="feedbackMessage"
          class="my-5"
          :placeholder="$t('SURVEY.FEEDBACK.PLACEHOLDER')"
        />
        <custom-button
          v-if="!isFeedbackSubmitted"
          class="font-medium float-right"
          @click="sendFeedback"
        >
          <spinner v-if="isUpdating && feedbackMessage" class="p-0" />
          {{ $t('SURVEY.FEEDBACK.BUTTON_TEXT') }}
        </custom-button>
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
import Banner from 'survey/components/Banner';
import CustomButton from 'shared/components/Button';
import TextArea from 'shared/components/TextArea.vue';
import configMixin from 'shared/mixins/configMixin';
import { getSurveyDetails, updateSurvey } from 'survey/api/survey';
import alertMixin from 'shared/mixins/alertMixin';
const BRAND_LOGO = '/brand-assets/logo.svg';
export default {
  name: 'Home',
  components: {
    Branding,
    Rating,
    CustomButton,
    TextArea,
    Spinner,
    Banner,
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
    conversationUUID() {
      const pageURL = window.location.href;
      const conversationId = pageURL.substr(pageURL.lastIndexOf('/') + 1);
      return conversationId;
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
    enableBanner() {
      return this.isRatingSubmitted || this.errorMessage;
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
    sendFeedback() {
      this.updateSurveyDetails();
    },
    imgUrlAlt() {
      this.logo = BRAND_LOGO;
    },
    async getSurveyDetails() {
      this.isLoading = true;
      try {
        const result = await getSurveyDetails({ uuid: this.conversationUUID });
        this.logo = result.data.inbox_avatar_url;
        this.surveyDetails = result?.data?.csat_survey_response;
        this.selectedRating = this.surveyDetails?.rating;
        this.feedbackMessage = this.surveyDetails?.feedback_message || '';
      } catch (error) {
        console.log('this.errorMessage', error);
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
          uuid: this.conversationUUID,
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
        this.isLoading = false;
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
