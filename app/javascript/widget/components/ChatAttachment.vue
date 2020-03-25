<template>
  <file-upload accept="image/*" @input-file="onFileUpload">
    <span class="attachment-button ">
      <i v-if="!isUploading.image"></i>
      <spinner v-if="isUploading" size="small" />
    </span>
  </file-upload>
</template>

<script>
import FileUpload from 'vue-upload-component';
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: { FileUpload, Spinner },
  props: {
    onAttach: {
      type: Function,
      default: () => {},
    },
  },
  data() {
    return { isUploading: false };
  },
  methods: {
    async onFileUpload(file) {
      this.isUploading = true;
      try {
        await this.onAttach({
          file_type: file.type,
          file: file.file,
        });
      } catch (error) {
        // Error
      }
      this.isUploading = false;
    },
  },
};
</script>
<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.attachment-button {
  background: transparent;
  border: 0;
  cursor: pointer;
  position: relative;
  padding-right: $space-smaller;
  display: block;
  width: 20px;
  height: 20px;

  i {
    padding: 0;
    width: 100%;
    height: 100%;
    display: block;
    background: white center center no-repeat;
    background-size: contain;
    background-image: url("data:image/svg+xml;charset=utf8,%3Csvg xmlns='http://www.w3.org/2000/svg' width='24' height='24' fill='none' stroke='red' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' class='feather feather-paperclip'%3E%3Cpath d='M21.44 11.05l-9.19 9.19a6 6 0 01-8.49-8.49l9.19-9.19a4 4 0 015.66 5.66l-9.2 9.19a2 2 0 01-2.83-2.83l8.49-8.48'/%3E%3C/svg%3E");
  }
}
</style>
