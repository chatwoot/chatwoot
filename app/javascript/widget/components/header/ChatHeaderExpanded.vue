<template>
  <header class="header-expanded py-8 px-6 bg-white relative box-border w-full">
    <div class="flex justify-between items-start">
      <img v-if="avatarUrl" class="logo" :src="avatarUrl" />
      <header-actions :show-popout-button="showPopoutButton" />
    </div>
    <h2
      class="text-slate-900 mt-5 text-4xl mb-3 font-normal"
      v-html="introHeading"
    />
    <p class="text-base text-black-700 leading-normal" v-html="introBody" />
  </header>
</template>

<script>
import { mapGetters } from 'vuex';
import HeaderActions from '../HeaderActions';
import configMixin from 'widget/mixins/configMixin';

export default {
  name: 'ChatHeaderExpanded',
  components: {
    HeaderActions,
  },
  mixins: [configMixin],
  props: {
    showPopoutButton: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    introHeading() {
      return this.channelConfig.welcomeTitle;
    },
    introBody() {
      return this.channelConfig.welcomeTagline;
    },
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/mixins.scss';

.header-expanded {
  @include shadow-large;

  .logo {
    width: 56px;
    height: 56px;
  }
}
</style>
