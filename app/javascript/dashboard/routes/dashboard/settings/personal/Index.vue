<template>
  <div
    class="flex flex-1 h-full justify-between flex-col m-0 bg-white dark:bg-slate-900 overflow-auto"
  >
    <div class="flex p-5 pt-16 mx-auto my-0">
      <div class="flex flex-col gap-8 min-w-[335px] sm:w-[720px]">
        <span class="font-medium dark:text-white text-slate-900 text-[24px]">
          Profile Settings
        </span>
        <div>
          <span
            class="text-slate-900 dark:text-slate-25 text-normal font-medium"
          >
            Profile picture
          </span>
          <!-- <thumbnail src="" username="John Doe" size="72px" /> -->
        </div>

        <div>
          <span class="text-slate-900 dark:text-slate-25 text-lg font-medium">
            Personal message signature
          </span>
          <div class="w-full h-[1px] bg-slate-200 dark:bg-slate-700 my-2" />
          <p class="text-slate-600 dark:text-slate-400 text-sm font-normal">
            Create a unique message signature to appear at the end of every
            message you send from any inbox. You can also include an inline
            image, which is supported in live-chat, email, and API inboxes.
          </p>
        </div>

        <div>
          <span class="text-slate-900 dark:text-slate-25 text-lg font-medium">
            Hot key to send messages
          </span>
          <div class="w-full h-[1px] bg-slate-200 dark:bg-slate-700 my-2" />
          <p class="text-slate-600 dark:text-slate-400 text-sm font-normal">
            You can select a hotkey (either Enter or Cmd/Ctrl+Enter) based on
            your preference of writing.
          </p>
          <div class="flex flex-col md:flex-row gap-4">
            <div class="flex-1 p-4 rounded-xl border border-slate-200">
              <div class="flex flex-row justify-between">
                <div class="text-sm">Enter (↵)</div>
                <input type="radio" name="hotkey" value="enter" />
              </div>
              <div class="text-xs pt-2">
                Send messages by pressing Enter key instead of clicking send
                button.
              </div>
              <img class="pt-4" src="/hot-key-enter.png" alt="Enter key" />
            </div>

            <div class="flex-1 p-4 border">BOX 2</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script setup>
// import Thumbnail from './Thumbnail.vue';
</script>
