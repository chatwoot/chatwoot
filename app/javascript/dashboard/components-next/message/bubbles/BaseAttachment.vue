<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import BaseBubble from './Base.vue';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  icon: { type: [String, Object], required: true },
  iconBgColor: { type: String, default: 'bg-n-alpha-3' },
  sender: { type: Object, default: () => ({}) },
  senderTranslationKey: { type: String, required: true },
  content: { type: String, required: true },
  action: {
    type: Object,
    required: true,
    validator: action => {
      return action.label && (action.href || action.onClick);
    },
  },
});

const { t } = useI18n();

const senderName = computed(() => {
  return props.sender.name;
});
</script>

<template>
  <BaseBubble
    class="overflow-hidden grid gap-4 min-w-64 p-0"
    data-bubble-name="attachment"
  >
    <slot name="before" />
    <div class="grid gap-3 px-3 pt-3 z-20">
      <div
        class="size-8 rounded-lg grid place-content-center"
        :class="iconBgColor"
      >
        <slot name="icon">
          <Icon :icon="icon" class="text-white size-4" />
        </slot>
      </div>
      <div class="space-y-1">
        <div v-if="senderName" class="text-n-slate-12 text-sm truncate">
          {{
            t(senderTranslationKey, {
              sender: senderName,
            })
          }}
        </div>
        <slot>
          <div v-if="content" class="truncate text-sm text-n-slate-11">
            {{ content }}
          </div>
        </slot>
      </div>
    </div>
    <div v-if="action" class="px-3 pb-3">
      <a
        v-if="action.href"
        :href="action.href"
        rel="noreferrer noopener nofollow"
        target="_blank"
        class="w-full block bg-n-solid-3 px-4 py-2 rounded-lg text-sm text-center"
      >
        {{ action.label }}
      </a>
      <button
        v-else
        class="w-full bg-n-solid-3 px-4 py-2 rounded-lg text-sm"
        @click="action.onClick"
      >
        {{ action.label }}
      </button>
    </div>
  </BaseBubble>
</template>
