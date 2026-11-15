<script setup>
import { useI18n } from 'vue-i18n';
import EmojiIcon from 'dashboard/components-next/emoji-icon-picker/EmojiIcon.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

defineProps({
  template: { type: Object, required: true },
  canCreate: { type: Boolean, default: false },
});

const emit = defineEmits(['use']);
const { t } = useI18n();
</script>

<template>
  <button
    type="button"
    :disabled="!canCreate"
    :aria-label="t('MONITORS.TEMPLATES.USE_NAMED', { name: template.name })"
    class="group flex min-w-0 flex-col gap-3 rounded-xl bg-n-surface-1 p-4 text-start outline outline-1 -outline-offset-1 outline-n-weak transition-colors enabled:hover:bg-n-alpha-1 enabled:hover:outline-n-strong focus-visible:outline-2 focus-visible:outline-n-brand disabled:cursor-default"
    @click="emit('use', template)"
  >
    <span class="flex w-full min-w-0 items-center gap-3">
      <span
        class="flex size-10 shrink-0 items-center justify-center rounded-xl outline outline-1 -outline-offset-1 outline-n-weak"
      >
        <EmojiIcon
          :value="template.icon"
          :color="template.icon_color"
          class="size-5"
        />
      </span>
      <span class="flex min-w-0 flex-1 flex-col gap-0.5">
        <span class="truncate text-heading-3 text-n-slate-12">
          {{ template.name }}
        </span>
        <span class="truncate text-label-small text-n-slate-11">
          {{ template.audience }}
        </span>
      </span>
      <Icon
        v-if="canCreate"
        icon="i-lucide-arrow-right"
        class="size-4 shrink-0 text-n-slate-10 transition-colors group-hover:text-n-brand rtl:rotate-180"
      />
    </span>
    <span class="text-body-main text-n-slate-11">
      {{ template.summary }}
    </span>
  </button>
</template>
