<template>
  <div class="example-typescript">
    <h1 id="example-title" class="example-title">Typescript Example</h1>
    <div class="upload">
      <ul>
        <li v-for="file in files" :key="file.id">
          <span>{{file.name}}</span> -
          <span>{{$formatSize(file.size)}}</span> -
          <span v-if="file.error">{{file.error}}</span>
          <span v-else-if="file.success">success</span>
          <span v-else-if="file.active">active</span>
          <span v-else-if="!!file.error">{{file.error}}</span>
          <span v-else></span>
        </li>
      </ul>
      <div class="example-btn">
        <file-upload
          class="btn btn-primary"
          post-action="/upload/post"
          extensions="gif,jpg,jpeg,png,webp"
          accept="image/png,image/gif,image/jpeg,image/webp"
          :multiple="true"
          :size="1024 * 1024 * 10"
          v-model="files"
          @input-filter="inputFilter"
          @input-file="inputFile"
          ref="upload">
          <i class="fa fa-plus"></i>
          Select files
        </file-upload>
        <button type="button" class="btn btn-success" v-if="!upload || !upload.active" @click.prevent="upload.active = true">
          <i class="fa fa-arrow-up" aria-hidden="true"></i>
          Start Upload
        </button>
        <button type="button" class="btn btn-danger"  v-else @click.prevent="upload.active = false">
          <i class="fa fa-stop" aria-hidden="true"></i>
          Stop Upload
        </button>
      </div>
    </div>
    <div class="pt-5 source-code">
      Source code: <a href="https://github.com/lian-yue/vue-upload-component/blob/master/docs/views/examples/Typescript.vue">/docs/views/examples/Typescript.vue</a>
    </div>
  </div>
</template>
<style>
.example-typescript label.btn {
  margin-bottom: 0;
  margin-right: 1rem;
}
</style>


<script lang="ts">
import {ref, SetupContext} from 'vue'
import  FileUpload from '../../../src/FileUpload.vue'
import type  { VueUploadItem } from '../../../src/FileUpload.vue'
export default {
  components: {
    FileUpload,
  },

  setup(props: unknown, context: SetupContext) {
    const upload = ref<InstanceType<typeof FileUpload> | null>(null)
    
    const files = ref([])

    function inputFilter(newFile: VueUploadItem | undefined, oldFile: VueUploadItem | undefined, prevent: (prevent?: boolean) => boolean) {
      if (newFile && !oldFile) {
        // Before adding a file
        // 添加文件前

        // Filter system files or hide files
        // 过滤系统文件 和隐藏文件
    
        if (newFile.name && /(\/|^)(Thumbs\.db|desktop\.ini|\..+)$/.test(newFile.name)) {
          return prevent()
        }
        
        // Filter php html js file
        // 过滤 php html js 文件
        if (newFile.name && /\.(php5?|html?|jsx?)$/i.test(newFile.name)) {
          return prevent()
        }
      }
    }

    function inputFile(newFile: VueUploadItem | undefined, oldFile: VueUploadItem | undefined) {
      if (newFile && !oldFile) {
        // add
        console.log('add', newFile)
      }
      if (newFile && oldFile) {
        // update
        console.log('update', newFile)
      }

      if (!newFile && oldFile) {
        // remove
        console.log('remove', oldFile)
      }
    }

    return {
      files,
      upload,
      inputFilter,
      inputFile,
    }
  }
}
</script>

