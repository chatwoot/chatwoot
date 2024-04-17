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

        <personal-wrapper
          header="Hot key to send messages"
          description="You can select a hotkey (either Enter or Cmd/Ctrl+Enter) based on your
          preference of writing."
          :show-action-button="false"
        >
          <template #settingsItem>
            <div class="flex flex-col justify-between w-full gap-4 sm:flex-row">
              <button
                v-for="keyOption in keyOptions"
                :key="keyOption.key"
                class="p-0 cursor-pointer"
              >
                <hot-key-card
                  :heading="keyOption.heading"
                  :content="keyOption.content"
                  :src="keyOption.src"
                  :active="keyOption.key === 'enter'"
                />
              </button>
            </div>
          </template>
        </personal-wrapper>
        <change-password />
        <personal-wrapper
          header="Audio notifications"
          description="Enable audio notifications in dashboard for new messages and conversations."
          :show-action-button="false"
        >
          <template #settingsItem>
            <audio-notifications />
          </template>
        </personal-wrapper>
        <personal-wrapper
          header="Notification preferences"
          :show-action-button="false"
        >
          <template #settingsItem>
            <notification-preferences />
          </template>
        </personal-wrapper>
        <personal-wrapper
          header="Access Token"
          description="This token can be used if you are building an API based integration."
          :show-action-button="false"
        >
          <template #settingsItem>
            <access-token />
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
import HotKeyCard from './HotKeyCard.vue';
import ChangePassword from './ChangePassword.vue';
import NotificationPreferences from './NotificationPreferences.vue';
import AudioNotifications from './AudioNotifications.vue';
import AccessToken from './AccessToken.vue';

const keyOptions = [
  {
    key: 'enter',
    src: '/assets/images/dashboard/profile/hot-key-enter.svg',
    heading: 'Enter (↵)',
    content:
      'Send messages by pressing Enter key instead of clicking send button.',
  },
  {
    key: 'cmd_enter',
    src: '/assets/images/dashboard/profile/hot-key-ctrl-enter.svg',
    heading: 'CMD / Ctrl + Enter (⌘ + ↵)',
    content:
      'Send messages by pressing Enter key instead of clicking send button.',
  },
];
</script>
