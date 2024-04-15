<template>
  <div class="flex items-center w-full overflow-y-auto">
    <div
      class="flex flex-col h-full p-5 pt-16 mx-auto my-0 bg-white dark:bg-slate-900 font-inter"
    >
      <div class="flex flex-col gap-8 sm:max-w-3xl">
        <h2 class="text-2xl font-medium text-slate-900 dark:text-white">
          Profile Settings
        </h2>
        <user-profile-picture username="John Doe" size="72px" />

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
            <div class="flex flex-row justify-between gap-4">
              <button
                v-for="keyOption in keyOptions"
                :key="keyOption.key"
                class="p-0 cursor-pointer"
              >
                <preview-card
                  :heading="keyOption.heading"
                  :content="keyOption.content"
                  :src="keyOption.src"
                  :active="keyOption.key === 'enter'"
                />
              </button>
            </div>
          </template>
        </personal-wrapper>

        <div class="flex flex-col w-full gap-4">
          <h4 class="text-lg font-medium text-slate-900 dark:text-slate-25">
            Change password
          </h4>
          <div class="flex flex-row items-center justify-between gap-4">
            <div class="flex-grow h-0.5 bg-slate-50 dark:bg-slate-700" />
          </div>
          <form-input
            name="current_password"
            class="flex-1"
            :class="{ error: false }"
            label="Current password"
            placeholder="Please enter your current password"
            :has-error="false"
            :error-message="$t('REGISTER.FULL_NAME.ERROR')"
          />
          <form-input
            name="new_password"
            class="flex-1"
            :class="{ error: false }"
            label="New password"
            placeholder="Please enter your new password"
            :has-error="false"
            :error-message="$t('REGISTER.FULL_NAME.ERROR')"
          />

          <form-input
            name="confirm_password"
            class="flex-1"
            :class="{ error: false }"
            label="Confirm password"
            placeholder="Please confirm your new password"
            :has-error="false"
            :error-message="$t('REGISTER.FULL_NAME.ERROR')"
          />
          <woot-button
            color-scheme="primary"
            class="rounded-xl w-fit"
            @click="$emit('click')"
          >
            Update password
          </woot-button>
        </div>

        <personal-wrapper
          header="Audio notifications"
          description="Enable audio notifications in dashboard for new messages and conversations."
          :show-action-button="false"
        >
          <template #settingsItem>
            <form-select
              name="timezone"
              spacing="compact"
              label="Alert tone"
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

            <div>
              <label
                class="flex justify-between pb-1 text-sm font-medium leading-6 text-slate-900 dark:text-white"
              >
                Alert events for conversations
              </label>
              <div
                class="flex flex-row justify-between h-10 max-w-xl p-2 border border-solid rounded-md border-slate-75 dark:border-slate-600"
              >
                <div
                  class="flex flex-row items-center justify-center gap-1 border-r border-slate-75 grow"
                >
                  <input type="radio" name="hotkey" value="enter" checked />
                  <label>None</label>
                </div>
                <div
                  class="flex flex-row items-center justify-center gap-1 border-r border-slate-75 grow"
                >
                  <input type="radio" name="hotkey" value="enter" />
                  <label>Assigned</label>
                </div>
                <div
                  class="flex flex-row items-center justify-center gap-1 grow"
                >
                  <input type="radio" name="hotkey" value="enter" />
                  <label>All</label>
                </div>
              </div>
            </div>
            <div>
              <label
                class="flex justify-between pb-1 text-sm font-medium leading-6 text-slate-900 dark:text-white"
              >
                Alert conditions
              </label>
              <div class="flex flex-row items-center justify-start gap-2">
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
              <div class="flex flex-row items-center justify-start gap-2">
                <input
                  type="checkbox"
                  name="send"
                  :checked="false"
                  class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
                />
                <label>
                  Send alerts every 30s until all the assigned conversations are
                  read
                </label>
              </div>
            </div>
          </template>
        </personal-wrapper>

        <personal-wrapper
          header="Notification preferences"
          :show-action-button="false"
        >
          <template #settingsItem>
            <div>
              <!-- Draw a line -->
              <div class="flex flex-row items-center justify-between gap-4">
                <div class="flex-grow h-0.5 bg-slate-50 dark:bg-slate-700" />
              </div>
              <div
                class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl"
              >
                <table-header-cell :span="6" label="Notification type" />
                <table-header-cell :span="3" label="Email" />
                <table-header-cell :span="3" label="Push notification" />
              </div>
              <div
                class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl"
              >
                <div
                  class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 rtl:text-right"
                >
                  <span class="text-slate-700 dark:text-slate-200">
                    A new conversation is created
                  </span>
                </div>
                <div
                  class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
                >
                  <input
                    type="checkbox"
                    name="email"
                    :checked="true"
                    class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
                  />
                </div>
                <div
                  class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
                >
                  <input
                    type="checkbox"
                    name="email"
                    :checked="false"
                    class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
                  />
                </div>
              </div>
              <div
                class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl"
              >
                <div
                  class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 rtl:text-right"
                >
                  <span class="text-slate-700 dark:text-slate-200">
                    Conversation is assigned to you
                  </span>
                </div>
                <div
                  class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
                >
                  <input
                    type="checkbox"
                    name="email"
                    :checked="true"
                    class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
                  />
                </div>
                <div
                  class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
                >
                  <input
                    type="checkbox"
                    name="email"
                    :checked="false"
                    class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
                  />
                </div>
              </div>
              <div
                class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl"
              >
                <div
                  class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 rtl:text-right"
                >
                  <span class="text-slate-700 dark:text-slate-200">
                    Conversation is assigned to you
                  </span>
                </div>
                <div
                  class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
                >
                  <input
                    type="checkbox"
                    name="email"
                    :checked="true"
                    class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
                  />
                </div>
                <div
                  class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
                >
                  <input
                    type="checkbox"
                    name="email"
                    :checked="false"
                    class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
                  />
                </div>
              </div>
              <div
                class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl"
              >
                <div
                  class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 rtl:text-right"
                >
                  <span class="text-slate-700 dark:text-slate-200">
                    You are mentioned in a conversation
                  </span>
                </div>
                <div
                  class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
                >
                  <input
                    type="checkbox"
                    name="email"
                    :checked="true"
                    class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
                  />
                </div>
                <div
                  class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
                >
                  <input
                    type="checkbox"
                    name="email"
                    :checked="false"
                    class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
                  />
                </div>
              </div>
              <div
                class="grid content-center h-12 grid-cols-12 gap-4 py-0 rounded-t-xl"
              >
                <div
                  class="flex items-center gap-2 col-span-6 px-0 py-2 text-sm tracking-[0.5] text-slate-700 dark:text-slate-100 rtl:text-right"
                >
                  <span class="text-slate-700 dark:text-slate-200">
                    New message is created in an assigned conversation
                  </span>
                </div>
                <div
                  class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
                >
                  <input
                    type="checkbox"
                    name="email"
                    :checked="true"
                    class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
                  />
                </div>
                <div
                  class="flex items-center gap-2 col-span-3 py-2 px-0 text-sm tracking-[0.5] text-slate-700 dark:text-slate-50 text-left rtl:text-right"
                >
                  <input
                    type="checkbox"
                    name="email"
                    :checked="false"
                    class="m-0 border-[1.5px] shadow border-slate-200 dark:border-slate-600 appearance-none rounded-[4px] w-4 h-4 dark:bg-slate-800 focus:ring-1 focus:ring-slate-100 dark:focus:ring-slate-700 checked:bg-woot-600 dark:checked:bg-woot-600 after:content-[''] after:text-white checked:after:content-['✓'] after:flex after:items-center after:justify-center checked:border-t checked:border-woot-700 dark:checked:border-woot-300 checked:border-b-0 checked:border-r-0 checked:border-l-0 after:text-center after:text-xs after:font-bold after:relative after:-top-[1.5px]"
                  />
                </div>
              </div>
            </div>
          </template>
        </personal-wrapper>
        <personal-wrapper
          header="Access Token"
          description="This token can be used if you are building an API based integration."
          :show-action-button="false"
        >
          <template #settingsItem>
            <div class="flex flex-row justify-between gap-4">
              <form-input
                name="access_token"
                class="flex-1"
                type="password"
                value="1234567890"
                :class="{ error: false }"
                placeholder="Please enter your new password"
                :has-error="false"
                :error-message="$t('REGISTER.FULL_NAME.ERROR')"
              />
              <woot-button
                icon="copy"
                variant="hollow"
                color-scheme="secondary"
                class="rounded-xl w-fit"
                @click="$emit('click')"
              >
                Copy
              </woot-button>
            </div>
          </template>
        </personal-wrapper>
      </div>
    </div>
  </div>
</template>
<script setup>
import TableHeaderCell from 'dashboard/components/widgets/TableHeaderCell.vue';
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
const audioFiles = [
  { label: 'Ding', value: 'ding' },
  { label: 'Dong', value: 'dong' },
];
</script>
