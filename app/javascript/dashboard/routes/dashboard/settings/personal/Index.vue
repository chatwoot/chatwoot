<template>
  <div
    class="flex h-full flex-col p-5 pt-16 mx-auto my-0 bg-white dark:bg-slate-900 overflow-auto font-inter"
  >
    <div class="flex flex-col gap-8 sm:max-w-3xl">
      <h2 class="font-medium text-slate-900 dark:text-white text-2xl">
        Profile Settings
      </h2>
      <div>
        <span class="text-slate-900 dark:text-slate-25 text-normal font-medium">
          Profile picture
        </span>
        <!-- <thumbnail src="" username="John Doe" size="72px" /> -->
      </div>
      <personal-wrapper
        header="Personal message signature"
        description="Create a unique message signature to appear at the end of every message you send from any inbox. You can also include an inline image, which is supported in live-chat, email, and API inboxes."
      >
        <template #settingsItem>
          <message-signature />
          <form-input
            name="full_name"
            class="flex-1"
            :class="{ error: true }"
            :label="$t('REGISTER.FULL_NAME.LABEL')"
            :placeholder="$t('REGISTER.FULL_NAME.PLACEHOLDER')"
            :has-error="true"
            :error-message="$t('REGISTER.FULL_NAME.ERROR')"
          />
        </template>
      </personal-wrapper>

      <personal-wrapper
        header="Hot key to send messages"
        description="You can select a hotkey (either Enter or Cmd/Ctrl+Enter) based on your
          preference of writing."
      >
        <template #settingsItem>
          <div class="flex gap-4 flex-row">
            <button
              v-for="keyOption in keyOptions"
              :key="keyOption.key"
              class="cursor-pointer p-0"
            >
              <preview-card
                :heading="keyOption.heading"
                :content="keyOption.content"
                :src="keyOption.src"
                :active="true"
              />
            </button>
          </div>
        </template>
      </personal-wrapper>
    </div>
  </div>
</template>
<script setup>
import { ref } from 'vue';
import MessageSignature from '../profile/MessageSignature.vue';
// import Thumbnail from './Thumbnail.vue';
import PersonalWrapper from './PersonalWrapper.vue';
import PreviewCard from 'dashboard/components/ui/PreviewCard.vue';
import FormInput from 'v3/components/Form/Input.vue';
const credentials = ref({
  fullName: '',
});
const keyOptions = [
  {
    key: 'enter',
    src: '/assets/images/dashboard/profile/hot-key-enter.svg',
    heading: 'Enter key',
    content: 'Send messages by pressing the Enter key',
  },
  {
    key: 'cmd_enter',
    src: '/assets/images/dashboard/profile/hot-key-ctrl-enter.svg',
    heading: 'Enter key',
    content: 'Send messages by pressing the Enter key',
  },
];
</script>
