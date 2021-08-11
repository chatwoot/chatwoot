<template>
  <div
    class="w-full h-full flex flex-col flex-no-wrap overflow-hidden bg-white"
  >
    <div class="flex flex-1 overflow-auto">
      <div class="max-w-screen-sm w-full my-0 m-auto px-8 py-12">
        <img src="/brand-assets/logo.svg" alt="Chatwoot logo" class="logo" />
        <p class="text-black-700 text-lg leading-relaxed mt-4 mb-4">
          {{ $t('SURVEY.DESCRIPTION') }}
        </p>
        <label class="text-base font-medium text-black-800">
          {{ $t('SURVEY.RATING.LABEL') }}
        </label>
        <rating />
        <label class="text-base font-medium text-black-800">
          {{ $t('SURVEY.FEEDBACK.LABEL') }}
        </label>
        <text-area
          v-model="message"
          class="my-5"
          :placeholder="$t('SURVEY.FEEDBACK.PLACEHOLDER')"
        />
        <custom-button class="font-medium float-right">
          <spinner v-if="isSubmitted" class="p-0" />
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
import Branding from 'shared/components/Branding.vue';
import Rating from 'survey/components/Rating.vue';
import CustomButton from 'shared/components/Button';
import TextArea from 'shared/components/TextArea.vue';
import configMixin from 'shared/mixins/configMixin';
export default {
  name: 'Home',
  components: {
    Branding,
    Rating,
    CustomButton,
    TextArea,
  },
  mixins: [configMixin],
  data() {
    return {
      message: '',
      isSubmitted: false,
    };
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';
.logo {
  max-height: $space-large;
}
</style>
