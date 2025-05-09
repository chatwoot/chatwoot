<template>
  <header
    :style="{ position: 'relative' }"
    class="header-expanded pt-6 px-4 relative box-border w-full bg-transparent background-gradient"
  >
    <div
      class="flex items-start mx-2"
      :class="[avatarUrl ? 'justify-between' : 'justify-end']"
    >
      <img
        v-if="avatarUrl"
        class="h-10 rounded-[4px]"
        :src="avatarUrl"
        alt="Avatar"
      />

      <!-- <header-actions
        :show-popout-button="showPopoutButton"
        :show-end-conversation-button="false"
      /> -->
    </div>
    <h2
      v-dompurify-html="introHeading"
      class="mt-2 text-xl mb-1 font-medium heading mx-2"
      :style="{ color: 'var(--text-color)' }"
    />
    <p
      v-dompurify-html="introBody"
      class="text-sm leading-normal sub-heading opacity-70 mx-2"
      :style="{ color: 'var(--text-color)' }"
    />
    <div
      role="button"
      class="translate-y-1/2 bg-white rounded-lg max-w-full p-3 overflow-hidden cursor-pointer"
      :style="{
        boxShadow: '0px 2px 8px 0px #00000014, 0px 0px 2px 0px #00000029',
      }"
      @click="onTrackOrderClick"
    >
      <div class="flex items-center gap-2 rounded-lg hover:bg-[#F0F0F0] p-1">
        <img
          class="w-8 h-8"
          src="~dashboard/assets/images/delivery_icon.svg"
          alt="No Page Image"
        />
        <p class="text-[14px] font-medium mr-auto">Track your Order</p>
        <fluent-icon
          icon="chevron-right"
          size="14"
          class="text-slate-900 dark:text-slate-50 mr-2"
        />
      </div>
    </div>
    <button
      class="button transparent compact rn-close-button fixed top-3 right-3 !p-2"
      :style="{ color: 'var(--text-color)' }"
      @click="closeWindow"
    >
      <fluent-icon icon="dismiss" size="20" />
    </button>
  </header>
</template>

<script>
import darkModeMixin from 'widget/mixins/darkModeMixin.js';
import routerMixin from 'widget/mixins/routerMixin';
import { IFrameHelper, RNHelper } from 'widget/helpers/utils';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { mapActions } from 'vuex';

export default {
  name: 'ChatHeaderExpanded',
  components: {
    FluentIcon,
  },
  mixins: [darkModeMixin, routerMixin],
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
    color: {
      type: String,
      default: '',
    },
  },
  methods: {
    ...mapActions('conversation', ['sendMessage']),
    ...mapActions('conversationAttributes', ['getAttributes']),
    onTrackOrderClick() {
      this.sendMessage({
        content: 'Hey, I want to track my order.',
      });
      if (this.conversationSize === 0) {
        this.getAttributes();
      }
      this.replaceRoute('messages');
    },
    closeWindow() {
      if (IFrameHelper.isIFrame()) {
        IFrameHelper.sendMessage({ event: 'closeWindow' });
      } else if (RNHelper.isRNWebView) {
        RNHelper.sendMessage({ type: 'close-widget' });
      }
    },
  },
};
</script>

<style>
.background-gradient::before {
  position: fixed;
  z-index: -1;
  display: block;
  content: '';
  top: 0;
  left: 0;
  width: 100%;
  height: 50%;
  background: var(--brand-color);
  background: linear-gradient(
    180deg,
    var(--widget-color) -15%,
    var(--widget-color) 25%,
    var(--widget-color)
  );
}

.background-gradient::after {
  position: fixed;
  z-index: -1;
  display: block;
  content: '';
  top: calc(50% - 6rem);
  left: 0;
  width: 100%;
  height: 6rem;
  background: linear-gradient(180deg, hsla(0, 0%, 100%, 0), #fefefe 75%);
}
</style>
