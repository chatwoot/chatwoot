<template>
  <div class="flex flex-col items-center justify-center h-full">
    <img
      class="m-4 w-32 hidden dark:block"
      src="~dashboard/assets/images/no-chat-dark.svg"
      alt="No Chat dark"
    />
    <img
      class="m-4 w-32 block dark:hidden"
      src="~dashboard/assets/images/no-chat.svg"
      alt="No Chat"
    />
    <span
      class="text-sm text-slate-800 dark:text-slate-200 font-medium text-center"
    >
      {{ message }}
      <br />
    </span>
    <!-- Cmd bar, keyboard shortcuts placeholder -->
    <feature-placeholder />
  </div>
</template>

<script>
export default {
  props: {
    message: {
      type: String,
      required: true,
    },
  },
};
</script>
