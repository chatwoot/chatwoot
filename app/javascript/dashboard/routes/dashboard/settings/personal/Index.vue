<template>
  <div
    class="flex h-full flex-col p-5 pt-16 mx-auto my-0 bg-white dark:bg-slate-900 overflow-auto font-inter"
  >
    <div class="flex flex-col gap-8 sm:max-w-3xl">
      <h2 class="font-medium text-slate-900 dark:text-white text-2xl">
        Profile Settings
      </h2>
      <user-profile-picture username="John Doe" size="72px" />
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
          <form-select
            name="timezone"
            spacing="compact"
            label="Ding"
            placeholder="Ding"
            class="max-w-xl"
          >
            <option
              v-for="file in audioFiles"
              :key="file.label"
              :value="file.value"
            >
              {{ file.label }}
            </option>
          </form-select>
          <div
            class="flex flex-row p-2 justify-between max-w-xl h-10 rounded-md border border-solid border-slate-75 dark:border-slate-600"
          >
            <div
              class="flex flex-row gap-1 border-r border-slate-75 justify-center items-center grow"
            >
              <input type="radio" name="hotkey" value="enter" />
              <label>None</label>
            </div>
            <div
              class="flex flex-row gap-1 border-r border-slate-75 justify-center items-center grow"
            >
              <input type="radio" name="hotkey" value="enter" />
              <label>Assigned</label>
            </div>
            <div class="flex flex-row gap-1 grow justify-center items-center">
              <input type="radio" name="hotkey" value="enter" />
              <label>All</label>
            </div>
          </div>
          <div class="flex flex-row gap-1 items-center justify-start">
            <input
              type="checkbox"
              name="send"
              :checked="true"
              class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
            />
            <label>
              Send audio alerts only if the browser window is not active
            </label>
          </div>
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
import MessageSignature from '../profile/MessageSignature.vue';
import UserProfilePicture from './UserProfilePicture.vue';
import PersonalWrapper from './PersonalWrapper.vue';
import PreviewCard from 'dashboard/components/ui/PreviewCard.vue';
import FormInput from 'v3/components/Form/Input.vue';
import FormSelect from 'v3/components/Form/Select.vue';
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
const audioFiles = [
  { label: 'Ding', value: 'ding' },
  { label: 'Dong', value: 'dong' },
];
</script>
