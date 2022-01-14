<template>
  <div v-if="showHeaderActions" class="actions flex items-center">
    <button
      class="button transparent compact close-button"
      :class="{
        'rn-close-button': isRNWebView,
      }"
      @click="closeWindow"
    >
      <fluent-icon icon="dismiss" size="24" class="text-black-900" />
    </button>
    <dropdown-menu
      v-if="hasWidgetOptions"
      menu-placement="right"
      :open="showDropdown"
      :toggle-menu="handleMenuClick"
    >
      <!-- Button content -->
      <template v-slot:button>
        <fluent-icon icon="more-vertical" size="24" class="text-black-900" />
      </template>

      <!-- Opened dropdown content -->
      <template v-slot:content>
        <dropdown-menu-item
          v-if="showPopoutButton"
          :action="popoutWindow"
          text="Open in a new window"
          icon-name="open"
        />
        <dropdown-menu-item
          v-if="conversationStatus === 'open'"
          :action="resolveConversation"
          text="End conversation"
          icon-name="checkmark"
        />
      </template>
    </dropdown-menu>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';
import { IFrameHelper, RNHelper } from 'widget/helpers/utils';
import { buildPopoutURL } from '../helpers/urlParamsHelper';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import DropdownMenu from './dropdown/DropdownMenu';
import DropdownMenuItem from './dropdown/DropdownMenuItem';

export default {
  name: 'HeaderActions',
  components: { FluentIcon, DropdownMenu, DropdownMenuItem },
  props: {
    showPopoutButton: {
      type: Boolean,
      default: false,
    },
  },
  data: () => ({
    showDropdown: false,
  }),
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
      this.showDropdown = false;
      if (IFrameHelper.isIFrame()) {
        IFrameHelper.sendMessage({ event: 'closeWindow' });
      } else if (RNHelper.isRNWebView) {
        RNHelper.sendMessage({ type: 'close-widget' });
      }
    },
    handleMenuClick() {
      this.showDropdown = !this.showDropdown;
    },
    resolveConversation() {
      this.showDropdown = false;
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
