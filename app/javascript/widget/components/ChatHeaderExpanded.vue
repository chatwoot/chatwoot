<template>
  <header
    :style="{ backgroundColor: color, position: 'relative' }"
    class="header-expanded pt-6 pb-8 px-5 relative box-border w-full bg-transparent"
  >
    <div
      class="flex items-start"
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
      class="mt-2 text-xl mb-1 font-medium text-white"
    />
    <p
      v-dompurify-html="introBody"
      class="text-sm leading-normal text-[#F0F0F0]"
    />
    <div
      role="button"
      class="flex items-center bg-white rounded-lg absolute top-[90%] left-1/2 transform -translate-x-1/2 w-[95%] gap-2 max-w-full p-4 overflow-hidden shadow-[0_2px_10px_rgba(0,0,0,0.1)] shadow-[0_0px_2px_rgba(0,0,0,0.2)] cursor-pointer"
      @click="onTrackOrderClick"
    >
      <img
        class="w-8 h-8"
        src="~dashboard/assets/images/delivery_icon.svg"
        alt="No Page Image"
      />
      <p class="text-[14px] font-medium mr-auto">Track Order</p>
      <fluent-icon
        icon="chevron-right"
        size="14"
        class="text-slate-900 dark:text-slate-50"
      />
    </div>
  </header>
</template>

<script>
import darkModeMixin from 'widget/mixins/darkModeMixin.js';
import routerMixin from 'widget/mixins/routerMixin';
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
  },
};
</script>
