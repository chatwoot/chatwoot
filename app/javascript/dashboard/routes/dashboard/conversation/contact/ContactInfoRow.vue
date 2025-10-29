<script>
import { useAlert } from 'dashboard/composables';
import EmojiOrIcon from 'shared/components/EmojiOrIcon.vue';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    EmojiOrIcon,
    NextButton,
  },
  props: {
    href: {
      type: String,
      default: '',
    },
    icon: {
      type: String,
      required: true,
    },
    emoji: {
      type: String,
      required: true,
    },
    value: {
      type: String,
      default: '',
    },
    showCopy: {
      type: Boolean,
      default: false,
    },
  },
  methods: {
    async onCopy(e) {
      e.preventDefault();
      await copyTextToClipboard(this.value);
      useAlert(this.$t('CONTACT_PANEL.COPY_SUCCESSFUL'));
    },
  },
};
</script>

<template>
  <div class="w-full h-5 ltr:-ml-1 rtl:-mr-1">
    <a
      v-if="href"
      :href="href"
      class="flex items-center gap-2 text-n-slate-11 hover:underline"
    >
      <EmojiOrIcon
        :icon="icon"
        :emoji="emoji"
        icon-size="14"
        class="flex-shrink-0 ltr:ml-1 rtl:mr-1"
      />
      <span
        v-if="value"
        class="overflow-hidden text-sm whitespace-nowrap text-ellipsis"
        :title="value"
      >
        {{ value }}
      </span>
      <span v-else class="text-sm text-n-slate-11">
        {{ $t('CONTACT_PANEL.NOT_AVAILABLE') }}
      </span>
      <NextButton
        v-if="showCopy"
        ghost
        xs
        slate
        class="ltr:-ml-1 rtl:-mr-1"
        icon="i-lucide-clipboard"
        @click="onCopy"
      />
    </a>

    <div v-else class="flex items-center gap-2 text-n-slate-11">
      <EmojiOrIcon
        :icon="icon"
        :emoji="emoji"
        icon-size="14"
        class="flex-shrink-0 ltr:ml-1 rtl:mr-1"
      />
      <span
        v-if="value"
        v-dompurify-html="value"
        class="overflow-hidden text-sm whitespace-nowrap text-ellipsis"
      />
      <span v-else class="text-sm text-n-slate-11">
        {{ $t('CONTACT_PANEL.NOT_AVAILABLE') }}
      </span>
    </div>
  </div>
</template>
