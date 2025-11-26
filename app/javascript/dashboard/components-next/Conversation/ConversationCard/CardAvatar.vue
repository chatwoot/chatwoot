<script setup>
import { ref } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';

const props = defineProps({
  contact: { type: Object, required: true },
  selected: { type: Boolean, default: false },
  enableSelection: { type: Boolean, default: true },
  hideThumbnail: { type: Boolean, default: false },
});

const emit = defineEmits(['selectConversation']);

const hovered = ref(false);

const onThumbnailHover = () => {
  hovered.value = !props.hideThumbnail;
};

const onThumbnailLeave = () => {
  hovered.value = false;
};

const onSelectConversation = checked => {
  emit('selectConversation', checked);
};
</script>

<template>
  <div
    class="relative self-start"
    @mouseenter="onThumbnailHover"
    @mouseleave="onThumbnailLeave"
  >
    <Avatar
      v-if="!hideThumbnail"
      :name="contact.name"
      :src="contact.thumbnail"
      :size="24"
      :status="contact.availability_status"
      hide-offline-status
    >
      <template v-if="enableSelection" #overlay="{ size }">
        <label
          v-if="hovered || selected"
          class="flex items-center justify-center rounded-full cursor-pointer absolute inset-0 z-10 backdrop-blur-[2px]"
          :style="{ width: `${size}px`, height: `${size}px` }"
          @click.stop
        >
          <input
            :value="selected"
            :checked="selected"
            class="!m-0 cursor-pointer"
            type="checkbox"
            @change="onSelectConversation($event.target.checked)"
          />
        </label>
      </template>
    </Avatar>
  </div>
</template>
