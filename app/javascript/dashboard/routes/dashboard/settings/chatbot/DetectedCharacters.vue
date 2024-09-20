<script>
export default {
  props: {
    detectedChar: {
      default: 0,
      type: Number,
    },
    accountCharLimit: {
      default: 1000000,
      type: Number,
    },
  },
  computed: {
    formattedDetectedChar() {
      return this.detectedChar.toLocaleString();
    },
    formattedAccountCharLimit() {
      return this.accountCharLimit.toLocaleString();
    },
  },
  method: {
    contactUs() {
      const contactLink = 'https://www.onehash.ai/contact';
      window.open(contactLink, '_blank');
    },
  },
};
</script>

<template>
  <div
    class="overflow-hidden p-4 w-1/3 max-w-1/3 flex flex-col justify-center flex-nowrap h-full"
  >
    <div class="flex flex-col text-slate-700 p-3">
      <span class="text-slate-900 font-semibold text-md">{{
        $t('CHATBOTS.TOTAL_DETECTED_CHARACTERS')
      }}</span>
      <span class="text-sm">
        {{
          $t('CHATBOTS.LIMIT', {
            detectedChar: formattedDetectedChar,
            accountLimit: formattedAccountCharLimit,
          })
        }}
      </span>
    </div>
    <div class="flex flex-row">
      <a
        class="text-slate-700 dark:text-slate-100 w-40 h-10 my-2 flex items-center justify-center rounded-lg hover:bg-slate-25 dark:hover:bg-slate-700 dark:hover:text-slate-100 hover:text-slate-600 relative"
        href="https://onehash.ai/contact"
        target="_blank"
        rel="noopener nofollow noreferrer"
      >
        <fluent-icon
          icon="chat"
          size="16"
          class="text-slate-600 dark:text-slate-400 mr-2"
        />
        {{ $t('SIDEBAR_ITEMS.CONTACT_SUPPORT') }}
      </a>
    </div>
  </div>
</template>
