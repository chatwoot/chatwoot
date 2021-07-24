<template>
  <div
    class="w-full h-full flex flex-col flex-no-wrap overflow-hidden bg-white"
  >
    <div class="flex flex-1 overflow-auto">
      <div class="max-w-screen-sm w-full my-0 m-auto p-8">
        <img src="/brand-assets/logo.svg" alt="Chatwoot logo" class="logo" />
        <div class="text-black-800 text-sm leading-5 pt-5">
          {{ $t('SURVEY.DESCRIPTION') }}
        </div>
        <div class="text-xs font-medium text-black-800 pt-5">
          {{ $t('SURVEY.RATING.LABEL') }}
        </div>
        <rating />
        <text-area
          v-model="message"
          class="my-5"
          :label="$t('SURVEY.FEEDBACK.LABEL')"
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
import Rating from 'service/components/Rating.vue';
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
  props: {
    showHomePage: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      message: '',
      isSubmitted: false,
    };
  },
  computed: {},
};
</script>

<style scoped lang="scss">
.logo {
  max-height: 2rem;
}
</style>
