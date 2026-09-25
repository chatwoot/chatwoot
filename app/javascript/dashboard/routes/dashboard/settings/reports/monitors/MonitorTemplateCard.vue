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
  <article
    class="flex min-w-0 flex-col gap-3 rounded-xl border border-n-weak bg-n-surface-1 p-4"
  >
    <div class="flex min-w-0 items-center gap-3">
      <span
        class="flex size-10 shrink-0 items-center justify-center rounded-xl bg-n-alpha-2"
      >
        <EmojiIcon
          :value="template.icon"
          :color="template.icon_color"
          class="size-5"
        />
      </span>
      <div class="min-w-0">
        <h3 class="m-0 text-heading-3 text-n-slate-12">
          {{ template.name }}
        </h3>
        <p class="m-0 text-xs text-n-slate-10">{{ template.audience }}</p>
      </div>
    </div>
    <p class="m-0 flex-1 text-body-main text-n-slate-11">
      {{ template.summary }}
    </p>
    <button
      type="button"
      :disabled="!canCreate"
      :aria-label="t('MONITORS.TEMPLATES.USE_NAMED', { name: template.name })"
      class="min-h-11 self-start rounded-md text-sm font-medium text-n-brand hover:underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-n-brand disabled:cursor-not-allowed disabled:opacity-50"
      @click="emit('use', template)"
    >
      {{ t('MONITORS.TEMPLATES.USE') }}
      <Icon
        icon="i-lucide-arrow-right"
        class="inline size-4 rtl:rotate-180"
        aria-hidden="true"
      />
    </button>
  </article>
</template>
