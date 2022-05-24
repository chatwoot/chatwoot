<template>
  <div v-if="showHeaderActions" class="actions flex items-center">
    <button
      v-if="conversationStatus === 'open' && hasEndConversationEnabled"
      class="button transparent compact"
      :title="$t('END_CONVERSATION')"
      @click="resolveConversation"
    >
      <fluent-icon
        icon="sign-out"
        size="22"
        :class="$dm('text-black-900', 'dark:text-slate-50')"
      />
    </button>
    <button
      v-if="showPopoutButton"
      class="button transparent compact new-window--button "
      @click="popoutWindow"
    >
      <fluent-icon
        icon="open"
        size="22"
        :class="$dm('text-black-900', 'dark:text-slate-50')"
      />
    </button>
    <button
      class="button transparent compact close-button"
      :class="{
        'rn-close-button': isRNWebView,
      }"
      @click="closeWindow"
    >
      <fluent-icon
        icon="dismiss"
        size="24"
        :class="$dm('text-black-900', 'dark:text-slate-50')"
      />
    </button>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { IFrameHelper, RNHelper } from 'widget/helpers/utils';
import { popoutChatWindow } from '../helpers/popoutHelper';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import darkModeMixin from 'widget/mixins/darkModeMixin';
import configMixin from 'widget/mixins/configMixin';

export default {
  name: 'HeaderActions',
  components: { FluentIcon },
  mixins: [configMixin, darkModeMixin],
  props: {
    showPopoutButton: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    ...mapGetters({
      conversationAttributes: 'conversationAttributes/getConversationParams',
    }),
    isIframe() {
      return IFrameHelper.isIFrame();
    },
    isRNWebView() {
      return RNHelper.isRNWebView();
    },
    showHeaderActions() {
      return this.isIframe || this.isRNWebView || this.hasWidgetOptions;
    },
    conversationStatus() {
      return this.conversationAttributes.status;
    },
    hasWidgetOptions() {
      return this.showPopoutButton || this.conversationStatus === 'open';
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
      popoutChatWindow(
        origin,
        websiteToken,
        this.$root.$i18n.locale,
        authToken
      );
    },
    closeWindow() {
      if (IFrameHelper.isIFrame()) {
        IFrameHelper.sendMessage({ event: 'closeWindow' });
      } else if (RNHelper.isRNWebView) {
        RNHelper.sendMessage({ type: 'close-widget' });
      }
    },
    resolveConversation() {
      this.$store.dispatch('conversation/resolveConversation');
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
  }

  .close-button {
    display: none;
  }
  .rn-close-button {
    display: block !important;
  }
}
</style>
