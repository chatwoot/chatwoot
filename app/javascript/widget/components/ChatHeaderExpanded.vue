<template>
  <header class="header-expanded bg-white py-8 px-6 relative box-border w-full">
    <div class="flex justify-between items-start">
      <header-actions :show-popout-button="showPopoutButton" />
    </div>
    <h2
      class="text-slate-900 mt-6 text-4xl mb-3 font-normal"
      v-html="introHeading"
    />
    <img class="inbox--avatar" src="/rick2.png" alt="avatar" />
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
      default: '/rick2.png',
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

<style scoped lang="scss">
@import '~widget/assets/scss/mixins.scss';

$logo-size: 56px;

.header-expanded {
  .logo {
    width: $logo-size;
    height: $logo-size;
    border-radius: $logo-size;
  }
  .inbox--avatar {
    width: 3rem;
    height: 3rem;
  }
}
</style>
