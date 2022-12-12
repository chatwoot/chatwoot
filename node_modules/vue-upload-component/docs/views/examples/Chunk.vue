<template>
  <div class="example-simple">
    <h1 id="example-title" class="example-title">Chunk Upload Example</h1>

    <p>When using chunk uploads, the file will be uploaded in different parts (or chunks). All the files with a size higher than the set in the input will be uploaded using this method.</p>
    <p>You will be able to see the different parts being uploaded individually. Some parts might fail, and the package is prepared to <em>retry</em> up to a certain amount of times.</p>
    <p>You can also pause / resume the upload process.</p>

    <div class="upload">
      <div class="form-horizontal">
        <div class="form-group">
          <div class="col-sm-offset-2 col-sm-10">
            <div class="checkbox">
              <label>
                <input v-model="chunkEnabled" type="checkbox"> Use chunk upload
              </label>
            </div>
          </div>
        </div>

        <div class="form-group">
          <label for="inputMinSize" class="col-sm-2 control-label">Min Size</label>
          <div class="col-sm-10">
            <div class="input-group">
              <input id="inputMinSize" v-model="chunkMinSize" type="number" class="form-control">
              <span class="input-group-addon">MB</span>
            </div>
          </div>
        </div>

        <div class="form-group">
          <label for="inputMaxActive" class="col-sm-2 control-label">Max Active Chunks</label>
          <div class="col-sm-10">
            <input id="inputMaxActive" v-model="chunkMaxActive" type="number" class="form-control">
          </div>
        </div>

        <div class="form-group">
          <label for="inputMaxRetries" class="col-sm-2 control-label">Max Chunk Retries</label>
          <div class="col-sm-10">
            <input id="inputMaxRetries" v-model="chunkMaxRetries" type="number" class="form-control">
          </div>
        </div>
      </div>

      <table class="table table-striped table-condensed">
        <thead class="thead-dark">
          <tr>
            <th>Name</th>
            <th class="text-right">Size</th>
            <th class="text-right">Progress</th>
            <th>Status</th>
            <th>Pause</th>
            <th colspan="3" class="text-center">Chunks</th>
          </tr>
          <tr>
            <th colspan="5"></th>
            <th class="text-right">Total</th>
            <th class="text-right">Active</th>
            <th class="text-right">Completed</th>
          </tr>
        </thead>
        <tbody>
          <template v-for="file in files">
            <tr :key="file.id + '-info'">
              <td>{{ file.name }}</td>
              <td class="text-right">{{ file.size | formatSize }}</td>
              <td class="text-right">{{ file.progress }}%</td>

              <td v-if="file.error">{{ file.error }}</td>
              <td v-else-if="file.success">Success</td>
              <td v-else-if="file.active">Active</td>
              <td v-else> - </td>

              <td>
                <template v-if="file.chunk">
                  <button
                    class="btn btn-sm btn-danger"
                    v-if="file.active"
                    @click="file.chunk.pause()"
                  >
                    <i class="fa fa-pause"/>
                  </button>
                  <button
                    class="btn btn-sm btn-primary"
                    v-if="!file.active && file.chunk.hasChunksToUpload"
                    @click="file.chunk.resume()"
                  >
                    <i class="fa fa-play"/>
                  </button>
                </template>
              </td>

              <template v-if="file.chunk">
                <td class="text-right">{{ file.chunk.chunks.length }}</td>
                <td class="text-right">{{ file.chunk.chunksUploading.length }}</td>
                <td class="text-right">{{ file.chunk.chunksUploaded.length }}</td>
              </template>
              <template v-else>
                <td class="text-right"> - </td>
                <td class="text-right"> - </td>
                <td class="text-right"> - </td>
              </template>
            </tr>

            <tr :key="file.id + '-loading'">
              <td colspan="8">
                <div class="chunk-loading" v-if="file.chunk">
                  <span
                    v-for="(chunk, index) in file.chunk.chunks"
                    :key="index"
                    class="chunk-loading-part"
                    :class="{'chunk-loading-part__uploaded': chunk.uploaded}"
                  >
                    <template v-if="chunk.retries != file.chunk.maxRetries">
                      {{ file.chunk.maxRetries - chunk.retries }} error(s)
                    </template>
                  </span>
                </div>
              </td>
            </tr>
          </template>
        </tbody>
      </table>

      <div class="example-btn">
        <file-upload
          class="btn btn-primary"
          post-action="/upload/post"

          :chunk-enabled="chunkEnabled"
          :chunk="{
            action: '/upload/chunk',
            minSize: chunkMinSize * 1048576,
            maxActive: chunkMaxActive,
            maxRetries: chunkMaxRetries
          }"

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
      </div>
    </div>
    <div class="pt-5">
      Source code: <a href="https://github.com/lian-yue/vue-upload-component/blob/master/docs/views/examples/Chunk.vue">/docs/views/examples/Chunk.vue</a>
    </div>
  </div>
</template>
<style>
.example-simple label.btn {
  margin-bottom: 0;
  margin-right: 1rem;
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
      files: [],

      chunkEnabled: true,

      // 1MB by default
      chunkMinSize: 1,
      chunkMaxActive: 3,
      chunkMaxRetries: 5
    }
  },

  methods: {
    inputFilter(newFile, oldFile, prevent) {
      if (newFile && !oldFile) {
        // Before adding a file
        // 添加文件前

        // Filter system files or hide files
        // 过滤系统文件 和隐藏文件
        if (/(\/|^)(Thumbs\.db|desktop\.ini|\..+)$/.test(newFile.name)) {
          return prevent()
        }

        // Filter php html js file
        // 过滤 php html js 文件
        if (/\.(php5?|html?|jsx?)$/i.test(newFile.name)) {
          return prevent()
        }
      }
    },

    inputFile(newFile, oldFile) {
      if (newFile && !oldFile) {
        // add
        console.log('add', newFile)
        this.$refs.upload.active = true
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
  }
}
</script>

<style scoped>
  .chunk-loading {
    margin: -12px;
    display: flex;
    width: calc(100% + 24px);
  }

  .chunk-loading .chunk-loading-part {
    height: 25px;
    line-height: 25px;
    flex: 1;
    background: #ccc;
    font-size: 14px;
    color: white;
    text-align: center;
  }

  .chunk-loading .chunk-loading-part.chunk-loading-part__uploaded {
    background: #28A745;
  }
</style>

