<template>
  <div class="w-full h-5 ltr:-ml-1 rtl:-mr-1">
    <a
      v-if="href"
      :href="href"
      class="flex items-center gap-2 text-slate-800 dark:text-slate-100 hover:underline"
    >
      <emoji-or-icon
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
      <span v-else class="text-sm text-slate-300 dark:text-slate-600">{{
        $t('CONTACT_PANEL.NOT_AVAILABLE')
      }}</span>

      <woot-button
        v-if="showCopy"
        type="submit"
        variant="clear"
        size="tiny"
        color-scheme="secondary"
        icon="clipboard"
        class-names="p-0"
        @click="onCopy"
      />
    </a>

    <div
      v-else
      class="flex items-center gap-2 text-slate-800 dark:text-slate-100"
    >
      <emoji-or-icon
        :icon="icon"
        :emoji="emoji"
        icon-size="14"
        class="flex-shrink-0 ltr:ml-1 rtl:mr-1"
      />
      <span
        v-if="value"
        class="overflow-hidden text-sm whitespace-nowrap text-ellipsis"
      >
        {{ value }}
      </span>
      <span v-else class="text-sm text-slate-300 dark:text-slate-600">{{
        $t('CONTACT_PANEL.NOT_AVAILABLE')
      }}</span>
    </div>
  </div>
</template>
<script>
import { useAlert } from 'dashboard/composables';
import EmojiOrIcon from 'shared/components/EmojiOrIcon.vue';
import { copyTextToClipboard } from 'shared/helpers/clipboard';

export default {
  components: {
    EmojiOrIcon,
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
