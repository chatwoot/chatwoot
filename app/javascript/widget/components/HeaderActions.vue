<template>
  <div v-if="showHeaderActions" class="actions flex items-center">
    <button
      v-if="showPopoutButton"
      class="button transparent compact new-window--button"
      @click="popoutWindow"
    >
      <span class="ion-android-open"></span>
    </button>
    <button
      class="button transparent compact close-button"
      :class="{
        'rn-close-button': isRNWebView,
      }"
    >
      <span class="ion-android-close" @click="closeWindow"></span>
    </button>
  </div>
</template>
<script>
import { IFrameHelper, RNHelper } from 'widget/helpers/utils';
import { buildPopoutURL } from '../helpers/urlParamsHelper';

export default {
  name: 'HeaderActions',
  props: {
    showPopoutButton: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    isIframe() {
      return IFrameHelper.isIFrame();
    },
    isRNWebView() {
      return RNHelper.isRNWebView();
    },
    showHeaderActions() {
      return this.isIframe || this.isRNWebView;
    },
  },
  methods: {
    popoutWindow() {
      this.closeWindow();
      const {
        location: { origin },
        chatwootWebChannel: { websiteToken },
        authToken,
      } = window;

      const popoutWindowURL = buildPopoutURL({
        origin,
        websiteToken,
        locale: this.$root.$i18n.locale,
        conversationCookie: authToken,
      });
      const popoutWindow = window.open(
        popoutWindowURL,
        `webwidget_session_${websiteToken}`,
        'resizable=off,width=400,height=600'
      );
      popoutWindow.focus();
    },
    closeWindow() {
      if (IFrameHelper.isIFrame()) {
        IFrameHelper.sendMessage({
          event: 'toggleBubble',
        });
      } else if (RNHelper.isRNWebView) {
        RNHelper.sendMessage({ type: 'close-widget' });
      }
    },
  },
};
</script>
<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.actions {
  button {
    margin-left: $space-normal;
  }

  span {
    color: $color-heading;
    font-size: $font-size-large;

    &.ion-android-close {
      font-size: $font-size-big;
    }
  }

  .close-button {
    display: none;
  }
  .rn-close-button {
    display: block !important;
  }
}
</style>
