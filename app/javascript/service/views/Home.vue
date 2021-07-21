<template>
  <div
    class="w-full h-full flex flex-col flex-no-wrap overflow-hidden bg-white"
  >
    <div class="flex flex-1 overflow-auto">
      <div class="max-w-screen-sm w-full mt-0 mb-0 m-auto p-8">
        <img
          src="/brand-assets/logo.svg"
          alt="Chatwoot logo"
          class="logo mt-0 mb-0 m-auto"
        />
        <div class="text-black-800 text-sm leading-5 pt-5">
          Dear customer 👋 , please take a few moments to complete the
          satisafcations survey. Lorem ipsum dolor sit amet consectetur
          adipisicing elit. Quam consequatur aperiam, enim repellendus
          cupiditate non tenetur iusto possimus vero, repellat reprehenderit ad
          dolorem, magni quisquam impedit? Amet eligendi consequuntur labore.
        </div>
        <div class="text-xs font-medium text-black-800 pt-5">
          Rate your conversation
        </div>
        <rating />
        <text-area
          v-model="message"
          class="my-5"
          label="Do you have any thoguhts you'd like to share?"
          placeholder="Your feefback(optional)"
        />

        <custom-button class="font-medium">
          <spinner v-if="isSubmitted" class="p-0" />
          Submit
        </custom-button>
      </div>
    </div>
    <div class="footer-wrap flex-shrink-0 w-full flex flex-col relative">
      <branding></branding>
    </div>
  </div>
</template>

<script>
import Branding from 'service/components/Branding.vue';
import Rating from 'service/components/Rating.vue';
import CustomButton from 'shared/components/Button';
import TextArea from '../components/TextArea.vue';
import configMixin from '../mixins/configMixin';
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
