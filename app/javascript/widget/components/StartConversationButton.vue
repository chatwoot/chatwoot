<template>
  <custom-button
    class-names="text-sm w-full mt-2 font-medium px-8"
    :bg-color="widgetColor"
    :text-color="textColor"
    @click="startConversation"
  >
    <i class="ion-send" />
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
