<template>
  <div class="example-multiple">
    <h1 id="example-title" class="example-title">Multiple instances</h1>
    <div class="upload">
      <ul>
        <li v-for="(file, index) in files1" :key="file.id">
          <span>{{file.name}}</span> -
          <span>{{file.size | formatSize}}</span> -
          <span v-if="file.error">{{file.error}}</span>
          <span v-else-if="file.success">success</span>
          <span v-else-if="file.active">active</span>
          <span v-else-if="file.active">active</span>
          <span v-else></span>
        </li>
      </ul>
      <div class="example-btn">
        <file-upload
        class="btn btn-primary"
          input-id="file1"
          post-action="/upload/post"
          v-model="files1"
          ref="upload1">
          <i class="fa fa-plus"></i>
          Select files
        </file-upload>
        <label for="file1" class="btn btn-primary">Label Select files</label>
        <button type="button" class="btn btn-success" v-if="!$refs.upload1 || !$refs.upload1.active" @click.prevent="$refs.upload1.active = true">
          <i class="fa fa-arrow-up" aria-hidden="true"></i>
          Start Upload
        </button>
        <button type="button" class="btn btn-danger"  v-else @click.prevent="$refs.upload1.active = false">
          <i class="fa fa-stop" aria-hidden="true"></i>
          Stop Upload
        </button>
      </div>
    </div>


    <div class="upload">
      <ul>
        <li v-for="(file, index) in files2" :key="file.id">
          <span>{{file.name}}</span> -
          <span>{{file.size | formatSize}}</span> -
          <span v-if="file.error">{{file.error}}</span>
          <span v-else-if="file.success">success</span>
          <span v-else-if="file.active">active</span>
          <span v-else-if="file.active">active</span>
          <span v-else></span>
        </li>
      </ul>
      <div class="example-btn">
        <file-upload
          class="btn btn-primary"
          input-id="file2"
          post-action="/upload/post"
          v-model="files2"
          ref="upload2">
          <i class="fa fa-plus"></i>
          Select files
        </file-upload>
        <label for="file2" class="btn btn-primary">Label Select files</label>
        <button type="button" class="btn btn-success" v-if="!$refs.upload2 || !$refs.upload2.active" @click.prevent="$refs.upload2.active = true">
          <i class="fa fa-arrow-up" aria-hidden="true"></i>
          Start Upload
        </button>
        <button type="button" class="btn btn-danger"  v-else @click.prevent="$refs.upload2.active = false">
          <i class="fa fa-stop" aria-hidden="true"></i>
          Stop Upload
        </button>
      </div>
    </div>
    <div class="pt-5">
      Source code: <a href="https://github.com/lian-yue/vue-upload-component/blob/master/docs/views/examples/Multiple.vue">/docs/views/examples/Multiple.vue</a>
    </div>
  </div>
</template>
<style>
.example-multiple label.btn {
  margin-bottom: 0;
  margin-right: 1rem;
}
.example-multiple .upload {
  margin-bottom: 1rem;
}
</style>

<script>
import FileUpload from 'vue-upload-component'
export default {
  components: {
    FileUpload,
  },

  data() {
    return {
      files1: [],
      files2: [],
    }
  },
}
</script>
