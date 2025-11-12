<template>
  <div class="example-multiple">
    <h1 id="example-title" class="example-title">Multiple instances</h1>
    <div class="upload upload-drop-container-1">
      <div v-show="$refs.upload1 && $refs.upload1.dropActive" class="drop-active"
        :class="{ 'drop-element-active': $refs.upload1 && $refs.upload1.dropElementActive }">
        <h3>
          {{ $refs.upload1 && $refs.upload1.dropElementActive ?
          "Release the mouse to add to upload1 (element)"
          :
          "Drag and drop here to upload1" }}
        </h3>
      </div>

      <ul>
        <li v-for="(file) in files1" :key="file.id">
          <span>{{ file.name }}</span> -
          <span>{{ $formatSize(file.size) }}</span> -
          <span v-if="file.error">{{ file.error }}</span>
          <span v-else-if="file.success">success</span>
          <span v-else-if="file.active">active</span>
          <span v-else></span>
        </li>
      </ul>
      <h5 class="drop-title">Drag and drop files into the container to upload1</h5>
      <div class="example-btn">
        <file-upload class="btn btn-primary" input-id="file1" post-action="/upload/post" v-model="files1" ref="upload1"
          drop=".upload-drop-container-1" :drop-directory="true" :multiple="true">
          <i class="fa fa-plus"></i>
          Select files
        </file-upload>
        <label for="file1" class="btn btn-primary ml-2">Label Select files</label>
        <button type="button" class="btn btn-success" v-if="!$refs.upload1 || !$refs.upload1.active"
          @click.prevent="$refs.upload1.active = true">
          <i class="fa fa-arrow-up" aria-hidden="true"></i>
          Start Upload
        </button>
        <button type="button" class="btn btn-danger" v-else @click.prevent="$refs.upload1.active = false">
          <i class="fa fa-stop" aria-hidden="true"></i>
          Stop Upload
        </button>
      </div>

      <div class="footer-status">
        Drop: {{ $refs.upload1 ? $refs.upload1.drop : false }},
        Active: {{ $refs.upload1 ? $refs.upload1.active : false }},
        Uploaded: {{ $refs.upload1 ? $refs.upload1.uploaded : true }},
        Drop active: {{ $refs.upload1 ? $refs.upload1.dropActive : false }}
        Drop element active: {{ $refs.upload1 ? $refs.upload1.dropElementActive : false }}
      </div>
    </div>


    <div class="upload upload-drop-container-2">
      <div v-show="$refs.upload2 && $refs.upload2.dropActive" class="drop-active"
        :class="{ 'drop-element-active': $refs.upload2 && $refs.upload2.dropElementActive }">
        <h3>
          {{ $refs.upload2 && $refs.upload2.dropElementActive
          ?
          "Release the mouse to add to upload2 (element)"
          :
          "Drag and drop here to upload2" }}
        </h3>
      </div>
      <ul>
        <li v-for="(file) in files2" :key="file.id">
          <span>{{ file.name }}</span> -
          <span>{{ $formatSize(file.size) }}</span> -
          <span v-if="file.error">{{ file.error }}</span>
          <span v-else-if="file.success">success</span>
          <span v-else-if="file.active">active</span>
          <span v-else></span>
        </li>
      </ul>
      <h5 class="drop-title">Drag and drop files into the container to upload2</h5>
      <div class="example-btn">
        <file-upload class="btn btn-primary" input-id="file2" post-action="/upload/post" v-model="files2" ref="upload2"
          drop=".upload-drop-container-2" :drop-directory="true" :multiple="true">
          <i class="fa fa-plus"></i>
          Select files
        </file-upload>
        <label for="file2" class="btn btn-primary  ml-2">Label Select files</label>
        <button type="button" class="btn btn-success" v-if="!$refs.upload2 || !$refs.upload2.active"
          @click.prevent="$refs.upload2.active = true">
          <i class="fa fa-arrow-up" aria-hidden="true"></i>
          Start Upload
        </button>
        <button type="button" class="btn btn-danger" v-else @click.prevent="$refs.upload2.active = false">
          <i class="fa fa-stop" aria-hidden="true"></i>
          Stop Upload
        </button>
      </div>
      <div class="footer-status">
        Drop: {{ $refs.upload2 ? $refs.upload2.drop : false }},
        Active: {{ $refs.upload2 ? $refs.upload2.active : false }},
        Uploaded: {{ $refs.upload2 ? $refs.upload2.uploaded : true }},
        Drop active: {{ $refs.upload2 ? $refs.upload2.dropActive : false }}
        Drop element active: {{ $refs.upload2 ? $refs.upload2.dropElementActive : false }}
      </div>
    </div>
    <div class="pt-5 source-code">
      Source code: <a
        href="https://github.com/lian-yue/vue-upload-component/blob/master/docs/views/examples/Multiple.vue">/docs/views/examples/Multiple.vue</a>
    </div>
  </div>
</template>
<style>
.example-multiple label.btn {
  margin-bottom: 0;
  margin-right: 1rem;
}

.example-multiple .upload {
  margin: 1rem 0;
  border-bottom: 1px solid #ccc;
}

.example-multiple .drop-title {
  padding: 0.5rem 0;
}

.example-multiple .upload {
  position: relative;
}

.example-multiple .upload ul li {
  padding: .5rem 0;
  border-bottom: 1px solid #ddd;
}

.example-multiple .footer-status {
  padding: 1rem 0;
}

.example-multiple .drop-active {
  top: 0;
  bottom: 0;
  right: 0;
  left: 0;
  position: absolute;
  z-index: 9999;
  opacity: .3;
  text-align: center;
  background: #000;
  transition: opacity 0.5s ease, transform 0.5s ease;
}

.example-multiple .drop-element-active {
  opacity: .8;
}

.example-multiple .drop-active h3 {
  margin: -.5em 0 0;
  position: absolute;
  top: 50%;
  left: 0;
  right: 0;
  -webkit-transform: translateY(-50%);
  -ms-transform: translateY(-50%);
  transform: translateY(-50%);
  font-size: 40px;
  color: #fff;
  padding: 0;
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
