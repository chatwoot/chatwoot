<template>
  <header class="header-expanded bg-white py-6 px-5 relative box-border w-full">
    <div
      class="flex items-start"
      :class="[avatarUrl ? 'justify-between' : 'justify-end']"
    >
      <img v-if="avatarUrl" class="h-12 rounded-full" :src="avatarUrl" />
      <header-actions :show-popout-button="showPopoutButton" />
    </div>
    <h2
      class="text-slate-900 mt-5 text-3xl mb-3 font-normal"
      v-html="introHeading"
    />
    <p class="text-lg text-black-700 leading-normal" v-html="introBody" />
  </header>
</template>

<script>
import { mapGetters } from 'vuex';
import HeaderActions from './HeaderActions';
export default {
  name: 'ChatHeaderExpanded',
  components: {
    HeaderActions,
  },
  props: {
    avatarUrl: {
      type: String,
      default: '',
    },
    introHeading: {
      type: String,
      default: '',
    },
    introBody: {
      type: String,
      default: '',
    },
    showPopoutButton: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
  },
};
</script>
