<script>
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    label: {
      type: String,
      default: '',
    },
    src: {
      type: String,
      default: '',
    },
    usernameAvatar: {
      type: String,
      default: '',
    },
    deleteAvatar: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['onAvatarSelect', 'onAvatarDelete'],
  watch: {},
  methods: {
    handleImageUpload(event) {
      const [file] = event.target.files;

      this.$emit('onAvatarSelect', {
        file,
        url: file ? URL.createObjectURL(file) : null,
      });
    },
    onAvatarDelete() {
      this.$refs.file.value = null;
      this.$emit('onAvatarDelete');
    },
  },
};
</script>

<template>
  <div>
    <label>
      <span v-if="label">{{ label }}</span>
    </label>
    <woot-thumbnail
      v-if="src"
      size="80px"
      :src="src"
      :username="usernameAvatar"
    />
    <div v-if="src && deleteAvatar" class="avatar-delete-btn">
      <NextButton
        outline
        xs
        ruby
        :label="$t('INBOX_MGMT.DELETE.AVATAR_DELETE_BUTTON_TEXT')"
        @click="onAvatarDelete"
      />
    </div>
    <label>
      <input
        id="file"
        ref="file"
        type="file"
        accept="image/png, image/jpeg, image/jpg, image/gif, image/webp"
        @change="handleImageUpload"
      />
      <slot />
    </label>
  </div>
</template>

<style lang="scss" scoped>
.avatar-delete-btn {
  margin-top: var(--space-smaller);
  margin-bottom: var(--space-smaller);
}
</style>
