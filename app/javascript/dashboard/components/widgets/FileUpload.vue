<template>
  <div class="input-wrapper">
    <input type="file" name="file" @change="onChangeFile" />
    <span class="file-button">Choose</span>
    <span class="file-label" data-js-label>{{ fileName }}</span>
  </div>
</template>

<script>
export default {
  props: {
    value: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      fileName: 'No File Selected',
    };
  },
  methods: {
    onChangeFile(event) {
      this.fileName = event.target.files[0].name;
      this.$emit('input', [event.target.files[0]]);
    },
  },
};
</script>

<style scoped>
.input-wrapper {
  text-align: left;
  background: #fff;
  position: relative;
  border-radius: 3px;
  overflow: hidden;
  border: 1px solid var(--s-75);
  height: 39px;
  border-radius: var(--border-radius-normal);
}

.input-wrapper > [type='file'] {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  opacity: 0;
  z-index: 10;
  cursor: pointer;
  margin: 0;
}

.input-wrapper > .file-button {
  display: inline-block;
  cursor: pointer;
  background: var(--color-woot);
  padding: 10px 14px;
  margin-right: 8px;
  color: var(--white);
  font-size: 12px;
}

.input-wrapper > .file-label {
  color: #333;
  white-space: nowrap;
  opacity: 0.3;
}

.input-wrapper.-chosen > .file-label {
  opacity: 1;
}
</style>
