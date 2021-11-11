<template>
  <custom-button
    class-names="text-sm w-full mt-2 font-medium px-8"
    :bg-color="widgetColor"
    :text-color="textColor"
    @click="startConversation"
  >
    <svg
      width="24"
      height="24"
      fill="none"
      viewBox="0 0 24 24"
      xmlns="http://www.w3.org/2000/svg"
    >
      <path
        d="m12.815 12.197-7.532 1.256a.5.5 0 0 0-.386.318L2.3 20.728c-.248.64.421 1.25 1.035.943l18-9a.75.75 0 0 0 0-1.342l-18-9c-.614-.307-1.283.304-1.035.943l2.598 6.957a.5.5 0 0 0 .386.319l7.532 1.255a.2.2 0 0 1 0 .394Z"
        fill="#212121"
      />
    </svg>
    {{ $t('START_CONVERSATION') }}
  </custom-button>
</template>

<script>
import { mapGetters } from 'vuex';
import { getContrastingTextColor } from '@chatwoot/utils';
import CustomButton from 'shared/components/Button';
import configMixin from 'widget/mixins/configMixin';

export default {
  name: 'TeamAvailability',
  components: {
    CustomButton,
  },
  mixins: [configMixin],
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
      currentUser: 'contactV2/getCurrentUser',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    shouldGotoPreChat() {
      const { email: currentUserEmail = '' } = this.currentUser;
      if (this.preChatFormEnabled && !currentUserEmail) {
        return true;
      }
      return false;
    },
  },
  methods: {
    async startConversation() {
      if (this.shouldGotoPreChat) {
        this.$router.push({
          name: 'prechat',
        });
      } else {
        this.$router.push({
          name: 'chat',
          params: {
            conversationId: 0,
          },
        });
      }

      this.$emit('after');
    },
  },
};
</script>
<style lang="scss" scoped>
.start-conversation-wrap {
  @apply flex;
  @apply flex-col;
  @apply justify-center;
  @apply mx-4;
  @apply p-3;
  @apply bg-slate-25;
  @apply border border-solid;
  @apply border-slate-75;
  @apply rounded-xl;
}

.agent-names-online {
  @apply text-sm	text-slate-800;
  @apply mt-2;

  &::v-deep > span {
    @apply font-medium;
    @apply text-woot-700;
  }
}
</style>
