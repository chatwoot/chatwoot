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
        <img src="/brand-assets/logo.png" alt="Digitaltolk" class="mx-auto h-12 mb-5 w-auto block dark:hidden"/>
        <img src="/brand-assets/logo_dark.png" alt="Digitaltolk" class="mx-auto h-12 mb-5 w-auto hidden dark:block">
        <p
          v-if="!isRatingSubmitted"
          class="text-black-700 text-lg leading-relaxed mb-8"
        >
          <!-- {{ $t('SURVEY.DESCRIPTION', { inboxName }) }} -->
          Hej! 👋, Vi vore tacksamma för att få dina synpunkter på konversationen du haft me oss.
        </p>
      </div>

      <div v-for="survey in surveys" :key="survey.id">
        <response :survey="survey"/>
      </div>
      <div class="mb-3">
        <branding />
      </div>
    </div>
  </div>
</template>

<script>
  import { getSurveyDetails } from 'survey/api/survey';
  import Response from './Response.vue';
  import Branding from 'shared/components/Branding.vue';
  import Spinner from 'shared/components/Spinner.vue';

  export default {
    components: {
      Branding,
      Response,
      Spinner,
    },
    data() {
      return {
        isLoading: false,
        surveys: [],
        logo: null,
        inboxName: null,
      }
    },
    computed: {
      surveyId() {
        const pageURL = window.location.pathname;
        return pageURL.substring(pageURL.lastIndexOf('/') + 1);
      },
    },
    async mounted() {
      this.getSurveyDetails();
    },
    methods: {
      async getSurveyDetails() {
        this.isLoading = true;
        try {
          const result = await getSurveyDetails({ uuid: this.surveyId });
          this.surveys = result.data;

          if (this.surveys.length) {
            this.logo = this.surveys[0].inbox_avatar_url;
            this.inboxName = this.surveys[0].inbox_name;
          }
          console.log(this.surveys)
        } catch (error) {
          console.log(error)
        }
        this.isLoading = false;
      }
    },
  }
</script>