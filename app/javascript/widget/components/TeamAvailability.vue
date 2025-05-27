<script>
import { mapGetters } from 'vuex';
import { toRef } from 'vue';
import { getContrastingTextColor } from '@chatwoot/utils';
import { IFrameHelper } from 'widget/helpers/utils';
import { CHATWOOT_ON_START_CONVERSATION } from '../constants/sdkEvents';
import GroupedAvatars from 'widget/components/GroupedAvatars.vue';
import { useAvailability } from 'widget/composables/useAvailability';

export default {
  name: 'TeamAvailability',
  components: {
    GroupedAvatars,
  },
  props: {
    availableAgents: {
      type: Array,
      default: () => [],
    },
    hasConversation: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['startConversation'],
  setup(props) {
    const availableAgents = toRef(props, 'availableAgents');
    const { replyWaitMessage, isOnline } = useAvailability(availableAgents);

    return {
      replyWaitMessage,
      isOnline,
    };
  },
  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    textColor() {
      return getContrastingTextColor(this.widgetColor);
    },
    agentAvatars() {
      return this.availableAgents.map(agent => ({
        name: agent.name,
        avatar: agent.avatar_url,
        id: agent.id,
      }));
    },
  },
  methods: {
    startConversation() {
      this.$emit('startConversation');
      if (!this.hasConversation) {
        IFrameHelper.sendMessage({
          event: 'onEvent',
          eventIdentifier: CHATWOOT_ON_START_CONVERSATION,
          data: { hasConversation: false },
        });
      }
    },
  },
};
</script>

<template>
  <div
    class="flex flex-col gap-3 w-full shadow outline-1 outline outline-n-container rounded-xl bg-n-background dark:bg-n-solid-2 px-5 py-4"
  >
    <div class="flex items-center justify-between gap-2">
      <div class="flex flex-col gap-1">
        <div class="font-medium text-n-slate-12">
          {{
            isOnline
              ? $t('TEAM_AVAILABILITY.ONLINE')
              : $t('TEAM_AVAILABILITY.OFFLINE')
          }}
        </div>
        <div class="text-n-slate-11">
          {{ replyWaitMessage }}
        </div>
      </div>
      <GroupedAvatars v-if="isOnline" :users="availableAgents" />
    </div>
    <button
      class="inline-flex items-center gap-1 font-medium text-n-slate-12"
      :style="{ color: widgetColor }"
      @click="startConversation"
    >
      <span>
        {{
          hasConversation
            ? $t('CONTINUE_CONVERSATION')
            : $t('START_CONVERSATION')
        }}
      </span>
      <i class="i-lucide-chevron-right size-5 mt-px" />
    </button>
  </div>
</template>
