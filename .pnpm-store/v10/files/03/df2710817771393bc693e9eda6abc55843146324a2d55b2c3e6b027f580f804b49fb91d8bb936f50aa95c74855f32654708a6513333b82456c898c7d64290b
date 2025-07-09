<template>
  <file-upload
    name="file"
    post-action="/post"
    put-action="/put"
    :value="files"
    @input="input"
    ref="upload">
    Add upload files
  </file-upload>
</template>
<script>
import FileUpload from '../src'
import { mapState } from 'vuex'
export default {
  components: {
    FileUpload,
  },

  computed: mapState({
    files: state => state.files
  }),

  methods: {
    // Files Event
    input(files) {
      this.$store.commit('updateFiles', files)
    },
  },
}
</script>
