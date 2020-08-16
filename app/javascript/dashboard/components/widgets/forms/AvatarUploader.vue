<template>
  <label>
    <span v-if="label">{{ label }}</span>
    <woot-thumbnail v-if="src" size="80px" :src="src" />
    <input
      id="file"
      ref="file"
      type="file"
      accept="image/*"
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
