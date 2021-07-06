<template>
  <div v-if="showHeaderActions" class="actions flex items-center">
    <button
      v-if="showPopoutButton"
      class="button transparent compact new-window--button"
      @click="popoutWindow"
    >
      <span>
        <svg width="22" height="22" viewBox="0 0 30 30" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path fill-rule="evenodd" clip-rule="evenodd" d="M11.4956 17.0529L12.9465 18.506L6.38113 25.0716L8.56063 27.2491L0.625 29.3749L2.75069 21.4411L4.93019 23.6186L11.4956 17.0529ZM18.5044 17.054L25.0698 23.6175L27.2493 21.44L29.375 29.3739L21.4394 27.2502L23.6189 25.0727L17.0535 18.505L18.5044 17.054ZM29.3742 0.625L27.2485 8.55882L25.069 6.38131L18.5056 12.9469L17.0526 11.4939L23.618 4.92826L21.4406 2.75076L29.3742 0.625ZM0.625207 0.625L8.56084 2.75076L6.38133 4.92826L12.9468 11.4939L11.4938 12.9469L4.9304 6.38131L2.7509 8.55882L0.625207 0.625Z" fill="black"/>
        </svg>
      </span>
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
