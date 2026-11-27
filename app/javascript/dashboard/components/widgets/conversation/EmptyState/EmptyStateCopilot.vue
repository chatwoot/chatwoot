<script setup>
import { defineAsyncComponent, ref, useTemplateRef } from 'vue';
import { COPILOT_OPEN_SOURCES } from 'dashboard/composables/useCopilotDot';
import { supportsCaptainAvatar } from 'dashboard/components-next/copilot/avatarSupport';
import CopilotAskBar from 'dashboard/components-next/copilot/CopilotAskBar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  message: {
    type: String,
    required: true,
  },
});

const AVATAR_SIZE = 96;

const CopilotAvatar = defineAsyncComponent(
  () => import('dashboard/components-next/copilot/CopilotAvatar.vue')
);
const isAvatarSupported = ref(supportsCaptainAvatar());

const question = ref('');
const avatar = useTemplateRef('avatar');
const onQuestionInput = () => avatar.value?.keyStroke();
</script>

<template>
  <div class="flex flex-col items-center w-[40rem] max-w-full px-4">
    <div class="flex items-center justify-center size-24 mb-4">
      <CopilotAvatar
        v-if="isAvatarSupported"
        ref="avatar"
        :state="question.trim() ? 'typing' : 'idle'"
        :size="AVATAR_SIZE"
        :label="$t('CAPTAIN.COPILOT.AVATAR_LABEL')"
        @unsupported="isAvatarSupported = false"
      />
      <Icon v-else icon="i-woot-captain" class="text-5xl text-n-slate-9" />
    </div>
    <span class="text-base font-medium text-center text-n-slate-12">
      {{ message }}
    </span>
    <CopilotAskBar
      v-model="question"
      :source="COPILOT_OPEN_SOURCES.EMPTY_STATE"
      class="mt-6"
      @input="onQuestionInput"
    />
  </div>
</template>
