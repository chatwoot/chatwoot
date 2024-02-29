<template>
  <div class="ltr:-ml-1 rtl:-mr-1 h-5 w-full">
    <a
      v-if="href"
      :href="href"
      class="flex items-center gap-2 text-slate-800 dark:text-slate-100 hover:underline"
    >
      <emoji-or-icon
        :icon="icon"
        :emoji="emoji"
        icon-size="14"
        class="ltr:ml-1 rtl:mr-1 flex-shrink-0"
      />
      <span
        v-if="value"
        class="overflow-hidden whitespace-nowrap text-ellipsis text-sm"
        :title="value"
      >
        {{ value }}
      </span>
      <span v-else class="text-slate-300 dark:text-slate-600 text-sm">{{
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
        class="ltr:ml-1 rtl:mr-1 flex-shrink-0"
      />
      <span
        v-if="value"
        class="overflow-hidden whitespace-nowrap text-ellipsis text-sm"
      >
        {{ value }}
      </span>
      <span v-else class="text-slate-300 dark:text-slate-600 text-sm">{{
        $t('CONTACT_PANEL.NOT_AVAILABLE')
      }}</span>
    </div>
  </div>
</template>
<script>
import alertMixin from 'shared/mixins/alertMixin';
import EmojiOrIcon from 'shared/components/EmojiOrIcon.vue';
import { copyTextToClipboard } from 'shared/helpers/clipboard';

export default {
  components: {
    EmojiOrIcon,
  },
  mixins: [alertMixin],
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
      this.showAlert(this.$t('CONTACT_PANEL.COPY_SUCCESSFUL'));
    },
  },
};
</script>
