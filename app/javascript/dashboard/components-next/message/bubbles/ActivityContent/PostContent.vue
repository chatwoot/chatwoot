<script setup>
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { computed } from 'vue';

const props = defineProps({
  contentAttributes: {
    type: Object,
    required: true,
  },
  toggleExpand: {
    type: Boolean,
    default: false,
  },
});

const parsedContent = computed(() => {
  return props.contentAttributes.post.content.split('\n');
});
</script>

<template>
  <div
    class="relative w-full space-y-2 px-4"
    :class="toggleExpand ? '' : 'max-h-[8rem] overflow-y-hidden'"
  >
    <div class="space-y-1">
      <span class="flex items-center gap-2 my-2 text-n-blue-text">
        <Icon icon="i-lucide-calendar" class="w-4 h-4" />
        <span class="text-xs">{{ contentAttributes.post.createdTime }}</span>
      </span>
      <p
        v-for="(line, index) in parsedContent"
        :key="`line-${index}`"
        class="text-xs text-left text-gray-800"
      >
        {{ line }}
      </p>
    </div>
    <div
      v-if="!toggleExpand"
      class="absolute bottom-0 left-0 right-0 h-32 bg-gradient-to-t from-black-200/80 to-transparent pointer-events-none"
    />
    <div class="grid gap-3">
      <div
        v-for="(attachment, index) in contentAttributes.post.attachments"
        :key="`attachment-${index}`"
        class="rounded-md overflow-hidden"
      >
        <img
          v-if="attachment.type === 'image'"
          :src="attachment.url"
          alt="Post attachment"
          class="rounded-md w-full object-cover"
        />
        <video
          v-else-if="attachment.type === 'video'"
          controls
          class="w-full rounded-md"
        >
          <source :src="attachment.url" type="video/mp4" />
          {{ $t('MESSAGES.ACTIVITY_MESSAGE.ATTACHMENT.UNSUPPORTED_BROWSER') }}
        </video>
        <p v-else class="text-xs text-gray-500 italic">
          {{ $t('MESSAGES.ACTIVITY_MESSAGE.ATTACHMENT.UNSUPPORTED_FILE_TYPE') }}
        </p>
      </div>
    </div>
  </div>
</template>
