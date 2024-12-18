<script setup>
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
defineProps({
  src: {
    type: String,
    default: '',
  },
  name: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['change', 'delete']);

const updateProfilePicture = e => {
  emit('change', e);
};

const deleteProfilePicture = () => {
  emit('delete');
};
</script>

<template>
  <div class="flex flex-col gap-2">
    <span class="text-sm font-medium text-ash-900">
      {{ $t('PROFILE_SETTINGS.FORM.PICTURE') }}
    </span>
    <Avatar
      :src="src || ''"
      :name="name || ''"
      :size="72"
      allow-upload
      @upload="updateProfilePicture"
      @delete="deleteProfilePicture"
    />
  </div>
</template>
