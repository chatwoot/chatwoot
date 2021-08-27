<template>
  <label>
    <span v-if="label">{{ label }}</span>
    <woot-thumbnail v-if="src" size="80px" :src="src" />
    <!-- ensure the same validations for attachment types are implemented in  backend models as well -->
    <input
      id="file"
      ref="file"
      type="file"
      accept="image/png, image/jpeg, image/gif"
      @change="handleImageUpload"
    />
    <slot></slot>
  </label>
</template>

<script>
export default {
  props: {
    label: {
      type: String,
      default: '',
    },
    src: {
      type: String,
      default: '',
    },
  },
  watch: {},
  methods: {
    handleImageUpload(event) {
      const [file] = event.target.files;

      this.$emit('change', {
        file,
        url: URL.createObjectURL(file),
      });
    },
  },
};
</script>
