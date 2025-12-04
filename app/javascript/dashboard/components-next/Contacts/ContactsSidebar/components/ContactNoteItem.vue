<script setup>
import { useTemplateRef, onMounted, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useToggle } from '@vueuse/core';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  note: {
    type: Object,
    required: true,
  },
  writtenBy: {
    type: String,
    required: true,
  },
  allowDelete: {
    type: Boolean,
    default: false,
  },
  collapsible: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['delete']);
const noteContentRef = useTemplateRef('noteContentRef');
const needsCollapse = ref(false);
const [isExpanded, toggleExpanded] = useToggle();
const { t } = useI18n();
const { formatMessage } = useMessageFormatter();

const handleDelete = () => {
  emit('delete', props.note.id);
};

onMounted(() => {
  if (props.collapsible) {
    // Check if content height exceeds approximately 4 lines
    // Assuming line height is ~1.625 and font size is ~14px
    const threshold = 14 * 1.625 * 4; // ~84px
    needsCollapse.value = noteContentRef.value?.clientHeight > threshold;
  }
});
</script>

<template>
  <div class="flex flex-col gap-1.5 border-b border-n-strong group/note">
    <div class="flex items-center justify-between w-full gap-1.5 min-w-0 h-9">
      <div class="min-w-0 truncate text-n-slate-11 text-xs font-440">
        {{ dynamicTime(note.createdAt) }}
      </div>
      <div class="flex items-center gap-1">
        <Button
          v-if="allowDelete"
          ghost
          ruby
          size="xs"
          icon="i-lucide-trash"
          class="opacity-0 group-hover/note:opacity-100"
          @click="handleDelete"
        />
        <Avatar
          v-tooltip.left="{
            content: writtenBy,
            delay: { show: 500, hide: 0 },
          }"
          :name="note?.user?.name || 'Bot'"
          :src="
            note?.user?.name
              ? note?.user?.thumbnail
              : '/assets/images/chatwoot_bot.png'
          "
          :size="16"
          rounded-full
        />
      </div>
    </div>
    <p
      ref="noteContentRef"
      v-dompurify-html="formatMessage(note.content || '')"
      class="mb-0 font-420 prose-sm prose-p:text-sm prose-p:leading-relaxed prose-p:mb-1 prose-p:mt-0 prose-ul:mb-1 prose-ul:mt-0 text-n-slate-12"
      :class="{
        'line-clamp-4': collapsible && !isExpanded && needsCollapse,
      }"
    />
    <p v-if="collapsible && needsCollapse">
      <Button
        variant="faded"
        color="blue"
        size="xs"
        :icon="isExpanded ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
        @click="() => toggleExpanded()"
      >
        <template v-if="isExpanded">
          {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.COLLAPSE') }}
        </template>
        <template v-else>
          {{ t('CONTACTS_LAYOUT.SIDEBAR.NOTES.EXPAND') }}
        </template>
      </Button>
    </p>
  </div>
</template>
