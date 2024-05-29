<template>
  <div class="flex flex-col gap-2">
    <span class="text-sm font-medium text-ash-900">
      {{ $t('PROFILE_SETTINGS.FORM.PICTURE') }}
    </span>
    <profile-avatar
      :src="src"
      :name="userNameWithoutEmoji"
      @change="updateProfilePicture"
      @delete="deleteProfilePicture"
    />
  </div>
</template>
<script setup>
import { computed } from 'vue';
import ProfileAvatar from 'v3/components/Form/ProfileAvatar.vue';
import { removeEmoji } from 'shared/helpers/emoji';
const props = defineProps({
  src: {
    type: String,
    default: '',
  },
  name: {
    type: String,
    default: '',
  },
});

const emits = defineEmits(['change', 'delete']);

const userNameWithoutEmoji = computed(() => removeEmoji(props.name));

const updateProfilePicture = e => {
  emits('change', e);
};

const deleteProfilePicture = () => {
  emits('delete');
};
</script>
