<template>
  <div class="unread-wrap">
    <div
      ref="aiNudge"
      class="unread-messages relative bg-gradient-to-br from-[#2e61f2] via-[#3f4fe9] to-[#b036d4] rounded-3xl p-5 max-w-[21.875rem] text-white shadow-2xl !pb-5"
      :style="`--widget-color: ${widgetColor};`"
    >
      <!-- Dismiss button -->
      <button
        class="absolute top-4 right-4 text-white hover:text-slate-300 transition-colors"
        @click="closeFullView"
      >
        <fluent-icon icon="dismiss" size="24" />
      </button>

      <!-- Main Content -->
      <div class="mb-4 pr-8 text-left">
        <h2 class="text-xl font-semibold">
          {{ message.content || message.text }}
        </h2>
      </div>

      <div
        v-if="filteredQuickReplies && filteredQuickReplies.length"
        class="space-y-3"
      >
        <button
          v-for="(reply, index) in filteredQuickReplies"
          :key="index"
          :disabled="previousSelectedReplies.includes(reply.id)"
          class="w-full bg-white/20 hover:bg-white/30 backdrop-blur-sm rounded-xl px-4 py-2 text-left text-white font-medium transition-all duration-200 hover:scale-[1.02]"
          :class="{
            'cursor-not-allowed': previousSelectedReplies.includes(reply.id),
            'opacity-50': previousSelectedReplies.includes(reply.id),
          }"
          @click.stop="handleQuickReply(reply)"
        >
          {{ reply.text }}
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import configMixin from '../mixins/configMixin';
import FluentIcon from 'shared/components/FluentIcon/Index.vue';
import { ON_UNREAD_MESSAGE_CLICK } from '../constants/widgetBusEvents';
import messageMixin from '../mixins/messageMixin';
import { IFrameHelper } from 'widget/helpers/utils';

export default {
  name: 'AINudge',
  components: {
    FluentIcon,
  },
  mixins: [configMixin, messageMixin],
  props: {
    message: {
      type: Object,
      required: true,
    },
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    companyName() {
      return `${this.$t('UNREAD_VIEW.COMPANY_FROM')} ${
        this.channelConfig.websiteName
      }`;
    },
    filteredQuickReplies() {
      return this.messageContentAttributes.items?.filter(
        reply => reply.text !== '' && reply.text !== null
      );
    },
    previousSelectedReplies() {
      return this.messageContentAttributes.previous_selected_replies || [];
    },
  },
  mounted() {
    IFrameHelper.sendMessage({
      event: 'updateIframeHeight',
      isFixedHeight: true,
      extraHeight: this.$refs.aiNudge.scrollHeight,
    });
  },
  methods: {
    closeFullView() {
      this.$emit('close');
    },
    async handleQuickReply(reply) {
      try {
        this.$emitter.emit(ON_UNREAD_MESSAGE_CLICK);
        await this.$store.dispatch(
          'aiNudge/updateMessageVisibilityAndQuickReply',
          {
            messageId: this.message.id,
            replyId: reply.id,
            previousSelectedReplies: [
              ...this.previousSelectedReplies,
              reply.id,
            ],
            shouldShow: true,
          }
        );
      } catch (error) {
        // Ignore error
      }
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~widget/assets/scss/variables';
.unread-wrap {
  width: 100%;
  height: auto;
  max-height: 100vh;
  background: transparent;
  display: flex;
  flex-direction: column;
  flex-wrap: nowrap;
  justify-content: flex-end;
  overflow: hidden;
  align-items: flex-end;
}
</style>
