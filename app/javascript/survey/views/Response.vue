<script>
import { useAlert } from 'dashboard/composables';
import Branding from 'shared/components/Branding.vue';
import Spinner from 'shared/components/Spinner.vue';
import Rating from 'survey/components/Rating.vue';
import Feedback from 'survey/components/Feedback.vue';
import Banner from 'survey/components/Banner.vue';
import CustomButton from 'shared/components/Button.vue';
import StarRating from 'shared/components/StarRating.vue';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { getSurveyDetails, updateSurvey } from 'survey/api/survey';

import { CSAT_DISPLAY_TYPES, CSAT_RATINGS } from 'shared/constants/messages';

export default {
  name: 'Response',
  components: {
    Branding,
    Rating,
    Spinner,
    Banner,
    Feedback,
    StarRating,
    CustomButton,
  },
  setup() {
    const { formatMessage } = useMessageFormatter();
    return { formatMessage };
  },
  data() {
    return {
      surveyDetails: null,
      isLoading: false,
      errorMessage: null,
      selectedRating: null,
      feedbackMessage: '',
      hasSubmittedFeedback: false,
      isUpdating: false,
      isPendingConfirmation: false,
      logo: '',
      inboxName: '',
      displayType: CSAT_DISPLAY_TYPES.EMOJI,
      messageContent: '',
    };
  },
  computed: {
    // Read here rather than destructured at module scope: the spec mounts without setting the
    // global, and a module-level read would freeze whatever existed at import time.
    pageConfig() {
      return window.globalConfig || {};
    },
    // Only the account's own name. Left empty for an account without a brand, so the footer
    // keeps the exact wording it had before -- Branding falls back to the installation name in
    // the locale's own translation, which is what the ~39 languages we do not ship rely on.
    brandName() {
      return this.pageConfig.BRAND_FROM_ACCOUNT
        ? this.pageConfig.BRAND_NAME || ''
        : '';
    },
    brandLogo() {
      return this.pageConfig.BRAND_LOGO_URL || '';
    },
    disableBranding() {
      return Boolean(this.pageConfig.DISABLE_BRANDING);
    },
    selectedRatingDetails() {
      return CSAT_RATINGS.find(({ value }) => value === this.selectedRating);
    },
    ratingLabel() {
      if (this.isRatingSubmitted && this.selectedRatingDetails) {
        return this.$t('SURVEY.RATING.SELECTED', {
          rating: this.$t(this.selectedRatingDetails.translationKey),
        });
      }
      return this.$t('SURVEY.RATING.LABEL');
    },
    surveyId() {
      // Read the path, not the href: the rating links in the survey email carry a
      // query string, which would otherwise be taken as part of the uuid.
      const { pathname } = window.location;
      return pathname.substring(pathname.lastIndexOf('/') + 1);
    },
    isRatingSubmitted() {
      // A pending confirmation means the rating on screen is not the stored one, so the
      // page is not in its resolved state: the success banner, the hidden prompt and the
      // feedback form all key off this.
      if (this.isPendingConfirmation) return false;

      return Boolean(this.surveyDetails?.rating);
    },
    isFeedbackSubmitted() {
      return (
        this.hasSubmittedFeedback || !!this.surveyDetails?.feedback_message
      );
    },
    isButtonDisabled() {
      if (!this.selectedRating) return true;
      if (this.isUpdating) return true;
      return false;
    },
    isEmojiType() {
      return this.displayType === CSAT_DISPLAY_TYPES.EMOJI;
    },
    isStarType() {
      return this.displayType === CSAT_DISPLAY_TYPES.STAR;
    },
    shouldShowBanner() {
      return this.isRatingSubmitted || this.errorMessage;
    },
    enableFeedbackForm() {
      return !this.isFeedbackSubmitted && this.isRatingSubmitted;
    },
    shouldShowErrorMessage() {
      return !!this.errorMessage;
    },
    shouldShowSuccessMessage() {
      return this.isRatingSubmitted;
    },
    message() {
      if (this.errorMessage) {
        return this.errorMessage;
      }
      return this.$t('SURVEY.RATING.SUCCESS_MESSAGE');
    },
    formattedMessageContent() {
      return this.formatMessage(this.messageContent, false);
    },
  },
  async mounted() {
    const loaded = await this.getSurveyDetails();
    if (loaded) this.applyRatingFromQuery();
  },
  methods: {
    // The survey email renders the scale inline, and each rating links here carrying its
    // value. It is only pre-selected, never submitted: email security gateways detonate
    // every link in a sandbox that runs JavaScript, so an automatic write would let a
    // scanner walk all five URLs and settle the rating before the recipient ever opens the
    // message. Persisting waits for a real gesture on this page.
    applyRatingFromQuery() {
      const rating = Number(
        new URLSearchParams(window.location.search).get('rating')
      );
      if (!CSAT_RATINGS.some(({ value }) => value === rating)) return;
      if (this.isFeedbackSubmitted) return;
      // Reopening the same link after confirming has nothing left to confirm, and asking
      // again would hide the feedback form behind a second confirmation.
      if (this.surveyDetails?.rating === rating) return;

      this.selectedRating = rating;
      this.isPendingConfirmation = true;
    },
    async confirmRating() {
      // Only on success: a failed write (an expired survey, a dropped connection) has to
      // leave the button on screen, or the contact is left with no way to send the rating
      // and, on a revised one, a page claiming the old rating went through.
      const saved = await this.updateSurveyDetails();
      if (saved) this.isPendingConfirmation = false;
    },
    async selectRating(rating) {
      if (this.isFeedbackSubmitted || this.isUpdating) return;
      this.selectedRating = rating;
      // Same rule as confirmRating: a revision stays pending until the write lands. Clearing
      // it first would make isRatingSubmitted fall back to the stored rating, so a failed
      // save would show the success banner for a rating the contact just replaced.
      const saved = await this.updateSurveyDetails();
      if (saved) this.isPendingConfirmation = false;
    },
    sendFeedback(message) {
      this.feedbackMessage = message;
      this.updateSurveyDetails({ markFeedbackSubmitted: true });
    },
    async getSurveyDetails() {
      this.isLoading = true;
      try {
        const result = await getSurveyDetails({ uuid: this.surveyId });
        // The inbox avatar is optional, and an inbox without one used to leave the page with
        // no mark at all. The account's own logo is the right thing to fall back to.
        this.logo = result.data.inbox_avatar_url || this.brandLogo;
        this.inboxName = result.data.inbox_name;
        this.surveyDetails = result?.data?.csat_survey_response;
        this.selectedRating = this.surveyDetails?.rating;
        this.feedbackMessage = this.surveyDetails?.feedback_message || '';
        this.displayType = result.data.display_type || CSAT_DISPLAY_TYPES.EMOJI;
        this.messageContent =
          result.data.content ||
          this.$t('SURVEY.DESCRIPTION', { inboxName: this.inboxName });
        this.setLocale(result.data.locale);
        return true;
      } catch (error) {
        const errorMessage = error?.response?.data?.message;
        this.errorMessage = errorMessage || this.$t('SURVEY.API.ERROR_MESSAGE');
        return false;
      } finally {
        this.isLoading = false;
      }
    },
    async updateSurveyDetails({ markFeedbackSubmitted = false } = {}) {
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
        if (markFeedbackSubmitted) {
          this.hasSubmittedFeedback = true;
        }
        // A retry after a failed write is a real path now that the confirmation button
        // survives the failure, and `message` prefers the error, so leaving it set would
        // show the success and error banners at once over a rating that did save.
        this.errorMessage = null;
        return true;
      } catch (error) {
        const errorMessage = error?.response?.data?.error;
        this.errorMessage = errorMessage || this.$t('SURVEY.API.ERROR_MESSAGE');
        useAlert(this.errorMessage);
        return false;
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

<template>
  <div
    v-if="isLoading"
    class="flex items-center justify-center flex-1 h-full min-h-[100dvh] bg-n-background"
  >
    <Spinner size="" />
  </div>
  <!-- The ground is a wash of the brand rather than a flat grey, so the page reads as the
       account's before a single word is. color-mix keeps it in a utility instead of a second
       server-rendered variable. -->
  <div
    v-else
    class="flex items-start justify-center w-full min-h-[100dvh] overflow-auto px-0 py-0 sm:items-center sm:px-6 sm:py-10 bg-[color-mix(in_srgb,var(--survey-brand)_6%,white)]"
  >
    <div
      class="flex flex-col w-full min-h-[100dvh] overflow-hidden bg-n-solid-1 sm:min-h-0 sm:max-w-lg sm:rounded-2xl sm:shadow-[0_20px_50px_-20px_rgba(15,23,42,0.25)]"
    >
      <!-- Identity before content: a hairline of the brand across the top says whose page this
           is even for an inbox with no avatar to show. -->
      <div class="h-1.5 shrink-0 bg-[color:var(--survey-brand)]" />
      <div class="w-full px-6 pt-8 pb-6 sm:px-10 sm:pt-10">
        <img
          v-if="logo"
          :src="logo"
          :alt="inboxName || brandName"
          class="mb-8 max-h-10 w-auto object-contain"
        />
        <div
          v-if="!isRatingSubmitted"
          v-dompurify-html="formattedMessageContent"
          class="mb-8 text-2xl font-semibold leading-snug tracking-tight text-balance text-n-slate-12 prose prose-bubble"
        />
        <Banner
          v-if="shouldShowBanner"
          :show-success="shouldShowSuccessMessage"
          :show-error="shouldShowErrorMessage"
          :message="message"
        />
        <!-- Always rendered, never behind a v-if: the group below takes its accessible name
             from this id, so removing the element once the rating is saved would leave an
             unnamed group for a screen reader on the revision flow. -->
        <p
          id="survey-rating-label"
          class="mb-3 text-xs font-semibold uppercase tracking-wider text-n-slate-10"
        >
          {{ ratingLabel }}
        </p>
        <!-- group, not radiogroup: the latter promises arrow-key navigation, which would mean
             managing roving focus for five buttons that already tab fine. -->
        <div role="group" aria-labelledby="survey-rating-label">
          <Rating
            v-if="isEmojiType"
            :selected-rating="selectedRating"
            :is-disabled="isFeedbackSubmitted || isUpdating"
            @select-rating="selectRating"
          />
          <StarRating
            v-if="isStarType"
            :selected-rating="selectedRating"
            :is-disabled="isFeedbackSubmitted || isUpdating"
            class="[&>button>span]:text-4xl !justify-start !px-0"
            @select-rating="selectRating"
          />
        </div>
        <div
          v-if="isPendingConfirmation"
          class="mt-8 flex flex-col items-stretch gap-3 sm:items-start"
        >
          <p class="m-0 text-sm text-n-slate-11">
            {{ $t('SURVEY.RATING.CONFIRM_LABEL') }}
          </p>
          <!-- bg-color as a prop, not a bg-* class: with no inline styles the button applies
               bg-n-brand itself, and the two would fight over source order. -->
          <CustomButton
            :disabled="isUpdating"
            bg-color="var(--survey-brand)"
            class="w-full !rounded-xl !py-3.5 text-base font-semibold transition-all duration-200 hover:bg-[image:linear-gradient(rgb(0_0_0/12%),rgb(0_0_0/12%))] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[color:var(--survey-brand)] sm:w-auto sm:!px-8"
            @click="confirmRating"
          >
            <Spinner v-if="isUpdating" class="p-0" />
            {{ $t('SURVEY.RATING.CONFIRM_BUTTON') }}
          </CustomButton>
        </div>
        <Feedback
          v-if="enableFeedbackForm"
          :is-updating="isUpdating"
          :is-button-disabled="isButtonDisabled"
          :selected-rating="selectedRating"
          @send-feedback="sendFeedback"
        />
      </div>
      <div class="mt-auto pb-5 pt-2 sm:mt-0">
        <Branding
          :brand-name="brandName"
          :own-logo="Boolean(brandLogo)"
          :disable-branding="disableBranding"
        />
      </div>
    </div>
  </div>
</template>
