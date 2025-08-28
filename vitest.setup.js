import { config } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import i18nMessages from 'dashboard/i18n';
import FloatingVue from 'floating-vue';

const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messages: i18nMessages,
});

config.global.plugins = [i18n, FloatingVue];
config.global.stubs = {
  WootModal: { template: '<div><slot/></div>' },
  WootModalHeader: { template: '<div><slot/></div>' },
  NextButton: { template: '<button><slot/></button>' },
  // Add stub for the specific NextButton component used in Whapi
  'dashboard/components-next/button/Button.vue': { 
    template: '<button><slot/></button>',
    props: ['isLoading', 'type', 'solid', 'blue', 'green', 'label', 'disabled', 'class'],
    emits: ['click']
  },
  // Add stub for Spinner component
  'dashboard/components-next/spinner/Spinner.vue': { 
    template: '<div class="spinner"></div>',
    props: ['size']
  },
  // Add stub for DotLottieVue component
  '@lottiefiles/dotlottie-vue': { 
    template: '<div class="lottie-animation"></div>',
    props: ['autoplay', 'loop', 'src'],
    emits: ['complete', 'finished', 'end', 'ready', 'load']
  },
};
