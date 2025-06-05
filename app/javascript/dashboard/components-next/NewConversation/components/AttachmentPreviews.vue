<script setup>
import { computed } from 'vue';
import { fileNameWithEllipsis } from '@chatwoot/utils';

import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  attachments: {
    type: Array,
    required: true,
  },
});

const emit = defineEmits(['update:attachments']);

const isTypeImage = file => {
  const type = file.content_type || file.type;
  return type.includes('image');
};

const filteredImageAttachments = computed(() => {
  return props.attachments.filter(attachment =>
    isTypeImage(attachment.resource)
  );
});

const filteredNonImageAttachments = computed(() => {
  return props.attachments.filter(
    attachment => !isTypeImage(attachment.resource)
  );
});

const removeAttachment = id => {
  const updatedAttachments = props.attachments.filter(
    attachment => attachment.resource.id !== id
  );
  emit('update:attachments', updatedAttachments);
};
</script>

<template>
  <div class="flex flex-col gap-4 p-4">
    <div
      v-if="filteredImageAttachments.length > 0"
      class="flex flex-wrap gap-3"
    >
      <div
        v-for="attachment in filteredImageAttachments"
        :key="attachment.id"
        class="relative group/image w-[4.5rem] h-[4.5rem]"
      >
        <img
          class="object-cover w-[4.5rem] h-[4.5rem] rounded-lg"
          :src="attachment.thumb"
        />
        <Button
          variant="ghost"
          icon="i-lucide-trash"
          color="slate"
          class="absolute top-1 right-1 !w-5 !h-5 transition-opacity duration-150 ease-in-out opacity-0 group-hover/image:opacity-100"
          @click="removeAttachment(attachment.resource.id)"
        />
      </div>
    </div>
    <div
      v-if="filteredNonImageAttachments.length > 0"
      class="flex flex-wrap gap-3"
    >
      <div
        v-for="attachment in filteredNonImageAttachments"
        :key="attachment.id"
        class="max-w-[18.75rem] inline-flex items-center h-8 min-w-0 bg-n-alpha-2 dark:bg-n-solid-3 rounded-lg gap-3 ltr:pl-3 rtl:pr-3 ltr:pr-2 rtl:pl-2"
      >
        <span class="text-sm font-medium text-n-slate-11">
          {{ fileNameWithEllipsis(attachment.resource) }}
        </span>
        <Button
          variant="ghost"
          icon="i-lucide-x"
          color="slate"
          size="xs"
          class="shrink-0 !h-5 !w-5"
          @click="removeAttachment(attachment.resource.id)"
        />
      </div>
    </div>
  </div>
</template>
