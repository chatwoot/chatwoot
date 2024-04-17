<template>
  <div class="flex items-center w-full overflow-y-auto">
    <div
      class="flex flex-col h-full p-5 pt-16 mx-auto my-0 bg-white dark:bg-slate-900 font-inter"
    >
      <div class="flex flex-col gap-8 sm:max-w-3xl">
        <h2 class="text-2xl font-medium text-slate-900 dark:text-white">
          Profile Settings
        </h2>
        <user-basic-profile username="John Doe" size="72px" />

        <personal-wrapper
          header="Personal message signature"
          description="Create a unique message signature to appear at the end of every message you send from any inbox. You can also include an inline image, which is supported in live-chat, email, and API inboxes."
          :show-action-button="true"
          button-text="Save message signature"
        >
          <template #settingsItem>
            <message-signature />
          </template>
        </personal-wrapper>
      </div>
    </div>
  </div>
</template>
<script setup>
import UserBasicProfile from './UserBasicProfile.vue';
import MessageSignature from './MessageSignature.vue';
import PersonalWrapper from './PersonalWrapper.vue';
</script>
