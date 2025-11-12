<template>
  <span :class="className">
    <slot></slot>
    <label :for="forId"></label>
    <input v-if="!reload" ref="input" type="file" :name="name" :id="forId" :accept="accept" :capture="capture"
      :disabled="disabled" :webkitdirectory="iDirectory" :allowdirs="iDirectory" :directory="iDirectory"
      :multiple="multiple && features.html5" @change="inputOnChange" />
  </span>
</template>
<style>
.file-uploads {
  overflow: hidden;
  position: relative;
  text-align: center;
  display: inline-block;
}

.file-uploads.file-uploads-html4 input,
.file-uploads.file-uploads-html5 label {
  /* background fix ie  click */
  background: #fff;
  opacity: 0;
  font-size: 20em;
  z-index: 1;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  position: absolute;
  width: 100%;
  height: 100%;
}

.file-uploads.file-uploads-html5 input,
.file-uploads.file-uploads-html4 label {
  /* background fix ie  click */
  position: absolute;
  background: rgba(255, 255, 255, 0);
  overflow: hidden;
  position: fixed;
  width: 1px;
  height: 1px;
  z-index: -1;
  opacity: 0;
}
</style>
<script lang="ts">
import { PropType, defineComponent, h } from "vue";

// @ts-ignore
import ChunkUploadDefaultHandler from './chunk/ChunkUploadHandler.js'

const CHUNK_DEFAULT_OPTIONS = {
  headers: {},
  action: '',
  minSize: 1048576,
  maxActive: 3,
  maxRetries: 5,
  handler: ChunkUploadDefaultHandler
}

export interface ChunkOptions {
  headers: { [key: string]: any };
  action: string;
  minSize: number;
  maxActive: number;
  maxRetries: number;
  handler: any;
}

export interface Data {
  active: boolean;
  dropActive: boolean;

  // 用于拖拽 激活判断容器 默认 document
  // https://github.com/lian-yue/vue-upload-component/pull/451
  dropElementActive: boolean;
  files: VueUploadItem[];
  maps: { [key: string]: VueUploadItem };
  destroy: boolean;
  uploading: number;
  features: Features;
  dropElement: null | HTMLElement;
  dropTimeout: null | number,
  reload: boolean;
}

export interface Features {
  html5: boolean;
  directory: boolean;
  drop: boolean;
}




export interface VueUploadItem {
  id: string;

  // 是否是文件对象
  readonly fileObject?: boolean,

  // 文件名
  name?: string;

  // 文件字节
  size?: number,

  // 文件 mime 类型
  type?: string,

  // 是否激活中
  active?: boolean,

  // 错误消息
  error?: Error | string,
  
  // 是否成功
  success?: boolean,
  
  // post 地址
  postAction?: string;

  // putAction 地址
  putAction?: string;

  // timeout
  timeout?: number;

  // 请求 data
  data?: { [key: string]: any }

  // 请求 headers
  headers?: { [key: string]: any }

  // 响应信息
  response?: { [key: string]: any };

  // 进度
  progress?: string;          // 只读

  // 速度
  speed?: 0; // 只读

  // xhr 信息
  file?: Blob; // 只读

  xhr?: XMLHttpRequest; // 只读

  // el 信息  仅有 html4 使用
  el?: HTMLInputElement;

  // iframe 信息 仅有 html4 使用
  iframe?: HTMLElement;             // 只读

  [key: string]: any;
}





export default defineComponent({
  compatConfig: {
    MODE: 3,
  },
  props: {
    inputId: {
      type: String,
    },
    name: {
      type: String,
      default: 'file',
    },
    accept: {
      type: String,
    },
    capture: {
    },
    disabled: {
      default: false,
    },
    multiple: {
      type: Boolean,
      default: false,
    },
    maximum: {
      type: Number,
    },
    addIndex: {
      type: [Boolean, Number],
    },
    directory: {
      type: Boolean,
    },
    createDirectory: {
      type: Boolean,
      default: false
    },
    postAction: {
      type: String,
    },
    putAction: {
      type: String,
    },
    customAction: {
      type: Function as PropType<(file: VueUploadItem, self: any) => Promise<VueUploadItem>>
    },
    headers: {
      type: Object as PropType<{ [key: string]: any }>,
      default: () => {
        return {}
      },
    },

    data: {
      type: Object as PropType<{ [key: string]: any }>,
      default: () => {
        return {}
      },
    },
    timeout: {
      type: Number,
      default: 0,
    },
    drop: {
      type: [Boolean, String, HTMLElement] as PropType<boolean | string | HTMLElement | null>,
      default: () => {
        return false
      },
    },
    dropDirectory: {
      type: Boolean,
      default: true,
    },
    size: {
      type: Number,
      default: 0,
    },
    extensions: {
      type: [RegExp, String, Array] as PropType<RegExp | string | string[]>,
      default: () => {
        return []
      },
    },
    modelValue: {
      type: Array as PropType<VueUploadItem[]>,
      default: () => {
        return []
      },
    },
    thread: {
      type: Number,
      default: 1,
    },
    // Chunk upload enabled
    chunkEnabled: {
      type: Boolean,
      default: false
    },
    // Chunk upload properties
    chunk: {
      type: Object as PropType<{ headers?: { [key: string]: any }; action?: string; minSize?: number; maxActive?: number; maxRetries?: number; handler?: any; }>,
      default: (): ChunkOptions => {
        return CHUNK_DEFAULT_OPTIONS
      }
    }
  },
  emits: [
    'update:modelValue',
    'input-filter',
    'input-file',
  ],
  data(): Data {

    return {
      files: this.modelValue,
      features: {
        html5: true,
        directory: false,
        drop: false,
      },
      active: false,
      dropActive: false,
      dropElementActive: false,
      uploading: 0,
      destroy: false,
      maps: {},
      dropElement: null,
      dropTimeout: null,
      reload: false,
    }
  },
  /**
   * mounted
   * @return {[type]} [description]
   */
  mounted() {
    const input = document.createElement('input')
    input.type = 'file'
    input.multiple = true
    // html5 特征
    if (window.FormData && input.files) {
      // 上传目录特征
      // @ts-ignore
      if (typeof input.webkitdirectory === 'boolean' || typeof input.directory === 'boolean') {
        this.features.directory = true
      }
      // 拖拽特征. 要兼容 relatedTarget
      if (this.features.html5 && typeof input.ondrop !== 'undefined' && this.isRelatedTargetSupported()) {
        this.features.drop = true
      }
    } else {
      this.features.html5 = false
    }
    // files 定位缓存
    this.maps = {}
    if (this.files) {
      for (let i = 0; i < this.files.length; i++) {
        const file = this.files[i]
        this.maps[file.id] = file
      }
    }

    // @ts-ignore
    this.$nextTick(() => {
      // 更新下父级
      if (this.$parent) {
        this.$parent.$forceUpdate()
        // 拖拽渲染
        this.$parent.$nextTick(() => {
          this.watchDrop(this.drop)
        })
      } else {
        // 拖拽渲染
        this.watchDrop(this.drop)
      }
    })
  },
  /**
   * beforeUnmount
   * @return {[type]} [description]
   */
  beforeUnmount() {
    // 已销毁
    this.destroy = true
    // 设置成不激活
    this.active = false
    // 销毁拖拽事件
    this.watchDrop(false)

    // 销毁不激活
    this.watchActive(false)
  },

  computed: {
    /**
     * uploading 正在上传的线程
     * @return {[type]} [description]
     */
    /**
     * uploaded 文件列表是否全部已上传
     * @return {[type]} [description]
     */
    uploaded() {
      let file
      for (let i = 0; i < this.files.length; i++) {
        file = this.files[i]
        if (file.fileObject && !file.error && !file.success) {
          return false
        }
      }
      return true
    },
    chunkOptions(): ChunkOptions {
      return Object.assign(CHUNK_DEFAULT_OPTIONS, this.chunk)
    },
    className(): Array<string | undefined> {
      return [
        'file-uploads',
        this.features.html5 ? 'file-uploads-html5' : 'file-uploads-html4',
        this.features.directory && this.directory ? 'file-uploads-directory' : undefined,
        this.features.drop && this.drop ? 'file-uploads-drop' : undefined,
        this.disabled ? 'file-uploads-disabled' : undefined,
      ]
    },
    forId(): string {
      return this.inputId || this.name
    },
    iMaximum(): number {
      if (this.maximum === undefined) {
        return this.multiple ? 0 : 1
      }
      return this.maximum
    },
    iExtensions(): RegExp | undefined {
      if (!this.extensions) {
        return
      }
      if (this.extensions instanceof RegExp) {
        return this.extensions
      }
      if (!this.extensions.length) {
        return
      }
      let exts: string[] = []
      if (typeof this.extensions === 'string') {
        exts = this.extensions.split(',')
      } else {
        exts = this.extensions
      }
      exts = exts.map(function (value) { return value.trim() }).filter(function (value) { return value })
      return new RegExp('\\.(' + exts.join('|').replace(/\./g, '\\.') + ')$', 'i')
    },
    iDirectory(): any {
      if (this.directory && this.features.directory) {
        return true
      }
      return undefined
    }
  },
  watch: {
    active(active: boolean) {
      this.watchActive(active)
    },
    dropActive(value: boolean) {
      this.watchDropActive(value)
      if (this.$parent) {
        this.$parent.$forceUpdate()
      }
    },
    drop(value: boolean) {
      this.watchDrop(value)
    },
    modelValue(files: VueUploadItem[]) {
      if (this.files === files) {
        return
      }
      this.files = files
      const oldMaps = this.maps
      // 重写 maps 缓存
      this.maps = {}
      for (let i = 0; i < this.files.length; i++) {
        const file = this.files[i]
        this.maps[file.id] = file
      }
      // add, update
      for (const key in this.maps) {
        const newFile = this.maps[key]
        const oldFile = oldMaps[key]
        if (newFile !== oldFile) {
          this.emitFile(newFile, oldFile)
        }
      }
      // delete
      for (const key in oldMaps) {
        if (!this.maps[key]) {
          this.emitFile(undefined, oldMaps[key])
        }
      }
    },
  },
  methods: {
    newId(): string {
      return Math.random().toString(36).substr(2)
    },
    // 清空
    clear() {
      if (this.files.length) {
        const files = this.files
        this.files = []
        // 定位
        this.maps = {}
        // 事件
        this.emitInput()
        for (let i = 0; i < files.length; i++) {
          this.emitFile(undefined, files[i])
        }
      }
      return true
    },
    // 选择
    get(id: string | VueUploadItem): VueUploadItem | false {
      if (!id) {
        return false
      }
      if (typeof id === 'object') {
        return this.maps[id.id || ''] || false
      }
      return this.maps[id] || false
    },
    // 添加
    add(_files: VueUploadItem | Blob | Array<VueUploadItem | Blob>, index?: number | boolean): VueUploadItem | VueUploadItem[] | undefined {
      // 不是数组整理成数组
      let files: Array<VueUploadItem | Blob>
      if (_files instanceof Array) {
        files = _files
      } else {
        files = [_files]
      }
      if (index === undefined) {
        // eslint-disable-next-line
        index = this.addIndex
      }
      // 遍历规范对象
      let addFiles: VueUploadItem[] = []
      for (let i = 0; i < files.length; i++) {
        let file: VueUploadItem | Blob = files[i]
        if (this.features.html5 && file instanceof Blob) {
          file = {
            id: '',
            file,
            size: file.size,
            // @ts-ignore
            name: file.webkitRelativePath || file.relativePath || file.name || 'unknown',
            type: file.type,
          }
        }
        file = file as VueUploadItem
        let fileObject = false
        if (file.fileObject === false) {
          // false
        } else if (file.fileObject) {
          fileObject = true
        } else if (typeof Element !== 'undefined' && file.el instanceof HTMLInputElement) {
          fileObject = true
        } else if (typeof Blob !== 'undefined' && file.file instanceof Blob) {
          fileObject = true
        }
        if (fileObject) {
          file = {
            fileObject: true,
            size: -1,
            name: 'Filename',
            type: '',
            active: false,
            error: '',
            success: false,
            putAction: this.putAction,
            postAction: this.postAction,
            timeout: this.timeout,
            ...file,
            response: {},
            progress: '0.00',          // 只读
            speed: 0,                  // 只读
            // file: undefined,
            // xhr: undefined,
            // el: undefined,
            // iframe: undefined,
          }
          file.data = {
            ...this.data,
            ...file.data ? file.data : {},
          }
          file.headers = {
            ...this.headers,
            ...file.headers ? file.headers : {},
          }
        }
        // 必须包含 id
        if (!file.id) {
          file.id = this.newId();
        }
        if (this.emitFilter(file, undefined)) {
          continue
        }
        // 最大数量限制
        if (this.iMaximum > 1 && (addFiles.length + this.files.length) >= this.iMaximum) {
          break
        }
        addFiles.push(file)
        // 最大数量限制
        if (this.iMaximum === 1) {
          break
        }
      }
      // 没有文件
      if (!addFiles.length) {
        return
      }
      // 如果是 1 清空
      if (this.iMaximum === 1) {
        this.clear()
      }
      // 添加进去 files
      let newFiles
      if (index === true || index === 0) {
        newFiles = addFiles.concat(this.files)
      } else if (index) {
        newFiles = this.files.concat([])
        newFiles.splice(index, 0, ...addFiles)
      } else {
        newFiles = this.files.concat(addFiles)
      }
      this.files = newFiles



      // 读取代理后的数据
      let index2 = 0
      if (index === true || index === 0) {
        index2 = 0
      } else if (index) {
        if (index >= 0) {
          if ((index + addFiles.length) > this.files.length) {
            index2 = this.files.length - addFiles.length
          } else {
            index2 = index
          }
        } else {
          index2 = this.files.length - addFiles.length + index
          if (index2 < 0) {
            index2 = 0
          }
        }
      } else {
        index2 = this.files.length - addFiles.length
      }

      addFiles = this.files.slice(index2, index2 + addFiles.length)


      // 定位
      for (let i = 0; i < addFiles.length; i++) {
        const file = addFiles[i]
        this.maps[file.id] = file
      }
      // 事件
      this.emitInput()
      for (let i = 0; i < addFiles.length; i++) {
        this.emitFile(addFiles[i], undefined)
      }
      return _files instanceof Array ? addFiles : addFiles[0]
    },
    // 添加表单文件
    addInputFile(el: HTMLInputElement): Promise<VueUploadItem[]> {
      const files: Array<VueUploadItem | File> = []
      const maximumValue = this.iMaximum




      // @ts-ignore
      const entrys: any = el.webkitEntries || el.entries || undefined
      if (entrys?.length) {
        return this.getFileSystemEntry(entrys).then((files) => {
          return this.add(files) as VueUploadItem[]
        })
      }


      if (el.files) {
        for (let i = 0; i < el.files.length; i++) {
          const file: File = el.files[i]
          files.push({
            id: '',
            size: file.size,
            // @ts-ignore
            name: file.webkitRelativePath || file.relativePath || file.name,
            type: file.type,
            file,
          })
        }
      } else {
        let names = el.value.replace(/\\/g, '/').split('/')
        if (!names || !names.length) {
          names = [el.value]
        }
        // @ts-ignore
        delete el.__vuex__
        files.push({
          id: '',
          name: names[names.length - 1],
          el,
        })
      }
      return Promise.resolve(this.add(files) as VueUploadItem[])
    },

    // 添加 DataTransfer
    addDataTransfer(dataTransfer: DataTransfer): Promise<VueUploadItem[] | undefined> {
      // dataTransfer.items 支持
      if (dataTransfer?.items?.length) {
        const entrys: Array<File | FileSystemEntry> = []
        // 遍历出所有 dataTransferVueUploadItem
        for (let i = 0; i < dataTransfer.items.length; i++) {
          const dataTransferTtem = dataTransfer.items[i]
          let entry: File | FileSystemEntry | null
          // @ts-ignore
          if (dataTransferTtem.getAsEntry) {
            // @ts-ignore
            entry = dataTransferTtem.getAsEntry() || dataTransferTtem.getAsFile()
          } else if (dataTransferTtem.webkitGetAsEntry) {
            entry = dataTransferTtem.webkitGetAsEntry() || dataTransferTtem.getAsFile()
          } else {
            entry = dataTransferTtem.getAsFile()
          }
          if (entry) {
            entrys.push(entry)
          }
        }
        return this.getFileSystemEntry(entrys).then((files) => {
          return this.add(files) as VueUploadItem[]
        })
      }

      // dataTransfer.files 支持
      const maximumValue = this.iMaximum
      const files: Array<VueUploadItem | File> = []
      if (dataTransfer.files.length) {
        for (let i = 0; i < dataTransfer.files.length; i++) {
          files.push(dataTransfer.files[i])
          if (maximumValue > 0 && files.length >= maximumValue) {
            break
          }
        }
        return Promise.resolve(this.add(files) as VueUploadItem[])
      }

      return Promise.resolve([])
    },


    // 获得 entrys    
    getFileSystemEntry(entry: Array<File | FileSystemEntry> | File | FileSystemEntry, path = ''): Promise<VueUploadItem[]> {
      // getFileSystemEntry(entry: any, path = ''): Promise<VueUploadItem[]> {
      return new Promise((resolve) => {
        const maximumValue = this.iMaximum

        if (!entry) {
          resolve([])
          return
        }

        if (entry instanceof Array) {
          // 多个
          const uploadFiles: VueUploadItem[] = []
          const forEach = (i: number) => {
            const v = entry[i]
            if (!v || (maximumValue > 0 && uploadFiles.length >= maximumValue)) {
              return resolve(uploadFiles)
            }
            this.getFileSystemEntry(v, path).then(function (results) {
              uploadFiles.push(...results)
              forEach(i + 1)
            })
          }
          forEach(0)
          return
        }

        if (entry instanceof Blob) {
          resolve([
            {
              id: '',
              size: entry.size,
              // @ts-ignore
              name: path + entry.name,
              type: entry.type,
              file: entry,
            }
          ])
          return
        }



        if (entry.isFile) {
          let fileEntry = entry as FileSystemFileEntry
          fileEntry.file(function (file: File) {
            resolve([
              {
                id: '',
                size: file.size,
                name: path + file.name,
                type: file.type,
                file,
              }
            ])
          })
          return
        }

        if (entry.isDirectory && this.dropDirectory) {
          let directoryEntry = entry as FileSystemDirectoryEntry
          const uploadFiles: VueUploadItem[] = []
          // 目录也要添加到文件列表
          if (this.createDirectory) {
            uploadFiles.push({
              id: '',
              name: path + directoryEntry.name,
              size: 0,
              type: 'text/directory',
              file: new File([], path + directoryEntry.name, { type: 'text/directory' }),
            })
          }

          const dirReader = directoryEntry.createReader()
          const readEntries = () => {
            dirReader.readEntries((entries: any) => {
              const forEach = (i: number) => {
                if ((!entries[i] && i === 0) || (maximumValue > 0 && uploadFiles.length >= maximumValue)) {
                  return resolve(uploadFiles)
                }
                if (!entries[i]) {
                  return readEntries()
                }
                this.getFileSystemEntry(entries[i], path + directoryEntry.name + '/').then(function (results) {
                  uploadFiles.push(...results)
                  forEach(i + 1)
                })
              }
              forEach(0)
            })
          }
          readEntries()
          return
        }

        resolve([])
      })
    },
    // 替换
    replace(id1: VueUploadItem | string, id2: VueUploadItem | string): boolean {
      const file1 = this.get(id1)
      const file2 = this.get(id2)
      if (!file1 || !file2 || file1 === file2) {
        return false
      }
      const files = this.files.concat([])
      const index1 = files.indexOf(file1)
      const index2 = files.indexOf(file2)
      if (index1 === -1 || index2 === -1) {
        return false
      }
      files[index1] = file2
      files[index2] = file1
      this.files = files
      this.emitInput()
      return true
    },
    // 移除
    remove(id: VueUploadItem | string): VueUploadItem | false {
      const file = this.get(id)
      if (file) {
        if (this.emitFilter(undefined, file)) {
          return false
        }
        const files = this.files.concat([])
        const index = files.indexOf(file)
        if (index === -1) {
          console.error('remove', file)
          return false
        }
        files.splice(index, 1)
        this.files = files
        // 定位
        delete this.maps[file.id]
        // 事件
        this.emitInput()
        this.emitFile(undefined, file)
      }
      return file
    },
    // 更新
    update(id: VueUploadItem | string, data: { [key: string]: any }): VueUploadItem | false {
      const file = this.get(id)
      if (file) {
        let newFile = {
          ...file,
          ...data
        }
        // 停用必须加上错误
        if (file.fileObject && file.active && !newFile.active && !newFile.error && !newFile.success) {
          newFile.error = 'abort'
        }
        if (this.emitFilter(newFile, file)) {
          return false
        }
        const files = this.files.concat([])
        const index = files.indexOf(file)
        if (index === -1) {
          console.error('update', file)
          return false
        }
        files.splice(index, 1, newFile)
        this.files = files
        newFile = this.files[index]

        // 删除  旧定位 写入 新定位 （已便支持修改id)
        delete this.maps[file.id]
        this.maps[newFile.id] = newFile
        // 事件
        this.emitInput()
        this.emitFile(newFile, file)
        return newFile
      }
      return false
    },
    // 预处理 事件 过滤器
    emitFilter(newFile: VueUploadItem | undefined, oldFile: VueUploadItem | undefined): boolean {
      let isPrevent = false
      this.$emit('input-filter', newFile, oldFile, function (prevent = true): boolean {
        isPrevent = prevent
        return isPrevent
      })
      return isPrevent
    },

    // 处理后 事件 分发
    emitFile(newFile: VueUploadItem | undefined, oldFile: VueUploadItem | undefined) {
      this.$emit('input-file', newFile, oldFile)
      if (newFile?.fileObject && newFile.active && (!oldFile || !oldFile.active)) {
        this.uploading++
        // 激活
        // @ts-ignore
        this.$nextTick(() => {
          setTimeout(() => {
            newFile && this.upload(newFile).then(() => {
              if (newFile) {
                // eslint-disable-next-line
                newFile = this.get(newFile) || undefined
              }
              if (newFile?.fileObject) {
                this.update(newFile, {
                  active: false,
                  success: !newFile.error
                })
              }
            }).catch((e: any) => {
              newFile && this.update(newFile, {
                active: false,
                success: false,
                error: e.code || e.error || e.message || e
              })
            })
          }, Math.ceil(Math.random() * 50 + 50))
        })
      } else if ((!newFile || !newFile.fileObject || !newFile.active) && oldFile && oldFile.fileObject && oldFile.active) {
        // 停止
        this.uploading--
      }
      // 自动延续激活
      // @ts-ignore
      if (this.active && (Boolean(newFile) !== Boolean(oldFile) || newFile.active !== oldFile.active)) {
        this.watchActive(true)
      }
    },
    emitInput() {
      this.$emit('update:modelValue', this.files)
    },
    // 上传
    upload(id: VueUploadItem | string): Promise<VueUploadItem> {
      const file = this.get(id)
      // 被删除
      if (!file) {
        return Promise.reject(new Error('not_exists'))
      }
      // 不是文件对象
      if (!file.fileObject) {
        return Promise.reject(new Error('file_object'))
      }
      // 有错误直接响应
      if (file.error) {
        if (file.error instanceof Error) {
          return Promise.reject(file.error)
        }
        return Promise.reject(new Error(file.error))
      }
      // 已完成直接响应
      if (file.success) {
        return Promise.resolve(file)
      }
      // 后缀
      if (file.name && this.iExtensions && file.type !== "text/directory") {
        if (file.name.search(this.iExtensions) === -1) {
          return Promise.reject(new Error('extension'))
        }
      }

      // 大小
      if (this.size > 0 && file.size !== undefined && file.size >= 0 && file.size > this.size && file.type !== "text/directory") {
        return Promise.reject(new Error('size'))
      }

      if (this.customAction) {
        return this.customAction(file, this)
      }
      if (this.features.html5) {
        if (this.shouldUseChunkUpload(file)) {
          return this.uploadChunk(file)
        }
        if (file.putAction) {
          return this.uploadPut(file)
        }
        if (file.postAction) {
          return this.uploadHtml5(file)
        }
      }
      if (file.postAction) {
        return this.uploadHtml4(file)
      }
      return Promise.reject(new Error('No action configured'))
    },
    /**
     * Whether this file should be uploaded using chunk upload or not
     *
     * @param Object file
     */
    shouldUseChunkUpload(file: VueUploadItem) {
      return this.chunkEnabled &&
        !!this.chunkOptions.handler &&
        file.size && file.size > this.chunkOptions.minSize
    },
    /**
     * Upload a file using Chunk method
     *
     * @param File file
     */
    uploadChunk(file: VueUploadItem): Promise<VueUploadItem> {
      const HandlerClass = this.chunkOptions.handler
      file.chunk = new HandlerClass(file, this.chunkOptions)
      return file.chunk.upload().then((res: any) => { return file })
    },
    uploadPut(file: VueUploadItem): Promise<VueUploadItem> {
      const querys = []
      let value
      for (const key in file.data) {
        value = file.data[key]
        if (value !== null && value !== undefined) {
          querys.push(encodeURIComponent(key) + '=' + encodeURIComponent(value))
        }
      }
      const putAction = file.putAction || ''
      const queryString = querys.length ? (putAction.indexOf('?') === -1 ? '?' : '&') + querys.join('&') : ''
      const xhr = new XMLHttpRequest()
      xhr.open('PUT', putAction + queryString)
      return this.uploadXhr(xhr, file, file.file as File)
    },
    uploadHtml5(file: VueUploadItem): Promise<VueUploadItem> {
      const form = new window.FormData()
      let value
      for (const key in file.data) {
        value = file.data[key]
        if (value && typeof value === 'object' && typeof value.toString !== 'function') {
          if (value instanceof File) {
            form.append(key, value, value.name)
          } else {
            form.append(key, JSON.stringify(value))
          }
        } else if (value !== null && value !== undefined) {
          form.append(key, value)
        }
      }

      // Moved file.name as the first option to set the filename of the uploaded file, since file.name
      // contains the full (relative) path of the file not just the filename as in file.file.filename
      // @ts-ignore
      form.append(this.name, file.file, file.name || file.file.name || file.file.filename)
      const xhr = new XMLHttpRequest()
      xhr.open('POST', file.postAction || '')
      return this.uploadXhr(xhr, file, form)
    },

    uploadXhr(xhr: XMLHttpRequest, ufile: VueUploadItem | undefined | false, body: FormData | Blob): Promise<VueUploadItem> {
      let file = ufile
      let speedTime = 0
      let speedLoaded = 0

      // 进度条
      xhr.upload.onprogress = (e: ProgressEvent) => {
        // 还未开始上传 已删除 未激活
        if (!file) {
          return
        }
        file = this.get(file)
        if (!e.lengthComputable || !file || !file.fileObject || !file.active) {
          return
        }

        // 进度 速度 每秒更新一次
        const speedTime2 = Math.round(Date.now() / 1000)
        if (speedTime2 === speedTime) {
          return
        }
        speedTime = speedTime2


        file = this.update(file, {
          progress: (e.loaded / e.total * 100).toFixed(2),
          speed: e.loaded - speedLoaded,
        })
        speedLoaded = e.loaded
      }

      // 检查激活状态
      let interval: number | undefined = window.setInterval(() => {
        if (file) {
          if ((file = this.get(file))) {
            if (file?.fileObject && !file.success && !file.error && file.active) {
              return
            }
          }
        }

        if (interval) {
          clearInterval(interval)
          interval = undefined
        }

        try {
          xhr.abort()
          xhr.timeout = 1
        } catch (e) {
        }
      }, 100)

      return new Promise((resolve: (u: VueUploadItem) => void, reject: (e: Error) => void) => {
        if (!file) {
          reject(new Error('not_exists'))
          return
        }
        let complete: boolean
        const fn = (e: ProgressEvent) => {
          // 已经处理过了
          if (complete) {
            return
          }
          complete = true
          if (interval) {
            clearInterval(interval)
            interval = undefined
          }
          if (!file) {
            return reject(new Error('not_exists'))
          }
          file = this.get(file)

          // 不存在直接响应
          if (!file) {
            return reject(new Error('not_exists'))
          }

          // 不是文件对象
          if (!file.fileObject) {
            return reject(new Error('file_object'))
          }

          // 有错误自动响应
          if (file.error) {
            if (file.error instanceof Error) {
              return reject(file.error)
            }
            return reject(new Error(file.error))
          }

          // 未激活
          if (!file.active) {
            return reject(new Error('abort'))
          }


          // 已完成 直接相应
          if (file.success) {
            return resolve(file)
          }

          const data: { [key: string]: any } = {}

          switch (e.type) {
            case 'timeout':
            case 'abort':
              data.error = e.type
              break
            case 'error':
              if (!xhr.status) {
                data.error = 'network'
              } else if (xhr.status >= 500) {
                data.error = 'server'
              } else if (xhr.status >= 400) {
                data.error = 'denied'
              }
              break
            default:
              if (xhr.status >= 500) {
                data.error = 'server'
              } else if (xhr.status >= 400) {
                data.error = 'denied'
              } else {
                data.progress = '100.00'
              }
          }

          if (xhr.responseText) {
            const contentType = xhr.getResponseHeader('Content-Type')
            if (contentType && contentType.indexOf('/json') !== -1) {
              data.response = JSON.parse(xhr.responseText)
            } else {
              data.response = xhr.responseText
            }
          }

          // 更新
          // @ts-ignore
          file = this.update(file, data)

          if (!file) {
            return reject(new Error('abort'))
          }

          // 有错误自动响应
          if (file.error) {
            if (file.error instanceof Error) {
              return reject(file.error)
            }
            return reject(new Error(file.error))
          }

          // 响应
          return resolve(file)
        }

        // 事件
        xhr.onload = fn
        xhr.onerror = fn
        xhr.onabort = fn
        xhr.ontimeout = fn


        // 超时
        if (file.timeout) {
          xhr.timeout = file.timeout
        }

        // headers
        for (const key in file.headers) {
          xhr.setRequestHeader(key, file.headers[key])
        }

        // 更新 xhr
        // @ts-ignore
        file = this.update(file, { xhr })

        // 开始上传
        file && xhr.send(body)
      })
    },
    uploadHtml4(ufile: VueUploadItem | undefined | false): Promise<VueUploadItem> {
      let file = ufile
      if (!file) {
        return Promise.reject(new Error('not_exists'))
      }
      const onKeydown = function (e: any) {
        if (e.keyCode === 27) {
          e.preventDefault()
        }
      }

      const iframe = document.createElement('iframe')
      iframe.id = 'upload-iframe-' + file.id
      iframe.name = 'upload-iframe-' + file.id
      iframe.src = 'about:blank'
      iframe.setAttribute('style', 'width:1px;height:1px;top:-999em;position:absolute; margin-top:-999em;')


      const form: HTMLFormElement = document.createElement('form')

      form.setAttribute('action', file.postAction || '')

      form.name = 'upload-form-' + file.id

      form.setAttribute('method', 'POST')
      form.setAttribute('target', 'upload-iframe-' + file.id)
      form.setAttribute('enctype', 'multipart/form-data')

      for (const key in file.data) {
        let value = file.data[key]
        if (value && typeof value === 'object' && typeof value.toString !== 'function') {
          value = JSON.stringify(value)
        }
        if (value !== null && value !== undefined) {
          const el = document.createElement('input')
          el.type = 'hidden'
          el.name = key
          el.value = value
          form.appendChild(el)
        }
      }

      form.appendChild(file.el as HTMLInputElement)

      document.body.appendChild(iframe).appendChild(form)


      const getResponseData = function (): string | null {
        let doc
        try {
          if (iframe.contentWindow) {
            doc = iframe.contentWindow.document
          }
        } catch (err) {
        }
        if (!doc) {
          try {
            // @ts-ignore
            doc = iframe.contentDocument ? iframe.contentDocument : iframe.document
          } catch (err) {
            // @ts-ignore
            doc = iframe.document
          }
        }
        // @ts-ignore
        if (doc?.body) {
          return doc.body.innerHTML
        }
        return null
      }

      return new Promise((resolve: (u: VueUploadItem) => void, reject: (e: Error) => void) => {
        setTimeout(() => {
          if (!file) {
            reject(new Error('not_exists'))
            return
          }

          file = this.update(file, { iframe })

          // 不存在
          if (!file) {
            return reject(new Error('not_exists'))
          }

          // 定时检查
          let interval: number | undefined = window.setInterval(() => {
            if (file) {
              if ((file = this.get(file))) {
                if (file.fileObject && !file.success && !file.error && file.active) {
                  return
                }
              }
            }

            if (interval) {
              clearInterval(interval)
              interval = undefined
            }
            // @ts-ignore
            iframe.onabort({ type: file ? 'abort' : 'not_exists' })
          }, 100)


          let complete: boolean
          const fn = (e: Event | string) => {
            // 已经处理过了
            if (complete) {
              return
            }
            complete = true

            if (interval) {
              clearInterval(interval)
              interval = undefined
            }

            // 关闭 esc 事件
            document.body.removeEventListener('keydown', onKeydown)

            if (!file) {
              return reject(new Error('not_exists'))
            }

            file = this.get(file)

            // 不存在直接响应
            if (!file) {
              return reject(new Error('not_exists'))
            }

            // 不是文件对象
            if (!file.fileObject) {
              return reject(new Error('file_object'))
            }

            // 有错误自动响应
            if (file.error) {
              if (file.error instanceof Error) {
                return reject(file.error)
              }
              return reject(new Error(file.error))
            }

            // 未激活
            if (!file.active) {
              return reject(new Error('abort'))
            }

            // 已完成 直接相应
            if (file.success) {
              return resolve(file)
            }

            let response: any = getResponseData()
            const data: { [key: string]: any } = {}
            if (typeof e === 'string') {
              return reject(new Error(e))
            }
            switch (e.type) {
              case 'abort':
                data.error = 'abort'
                break
              case 'error':
                if (file.error) {
                  data.error = file.error
                } else if (response === null) {
                  data.error = 'network'
                } else {
                  data.error = 'denied'
                }
                break
              default:
                if (file.error) {
                  data.error = file.error
                } else if (response === null) {
                  data.error = 'network'
                } else {
                  data.progress = '100.00'
                }
            }

            if (response !== null) {
              if (response && response.substr(0, 1) === '{' && response.substr(response.length - 1, 1) === '}') {
                try {
                  response = JSON.parse(response)
                } catch (err) {
                }
              }
              data.response = response
            }

            // 更新
            file = this.update(file, data)
            if (!file) {
              return reject(new Error('not_exists'))
            }

            if (file?.error) {
              if (file.error instanceof Error) {
                return reject(file.error)
              }
              return reject(new Error(file.error))
            }

            // 响应
            return resolve(file)
          }


          // 添加事件
          iframe.onload = fn
          iframe.onerror = fn
          iframe.onabort = fn


          // 禁止 esc 键
          document.body.addEventListener('keydown', onKeydown)

          // 提交
          form.submit()
        }, 50)
      }).then(function (res: VueUploadItem): VueUploadItem {
        iframe?.parentNode?.removeChild(iframe)
        return res
      }).catch(function (res: any) {
        iframe?.parentNode?.removeChild(iframe)
        return res
      })
    },

    watchActive(active: boolean) {
      let file
      let index = 0
      while ((file = this.files[index])) {
        index++
        if (!file.fileObject) {
          // 不是文件对象
        } else if (active && !this.destroy) {
          if (this.uploading >= this.thread || (this.uploading && !this.features.html5)) {
            break
          }
          if (!file.active && !file.error && !file.success) {
            this.update(file, { active: true })
          }
        } else {
          if (file.active) {
            this.update(file, { active: false })
          }
        }
      }
      if (this.uploading === 0) {
        this.active = false
      }
    },

    watchDrop(newDrop: boolean | string | HTMLElement | null, oldDrop: boolean | string | HTMLElement | undefined = undefined) {
      if (!this.features.drop) {
        return
      }
      if (newDrop === oldDrop) {
        return
      }

      // 移除挂载
      if (this.dropElement) {
        try {
          document.removeEventListener('dragenter', this.onDocumentDragenter, false)
          document.removeEventListener('dragleave', this.onDocumentDragleave, false)
          document.removeEventListener('dragover', this.onDocumentDragover, false)
          document.removeEventListener('drop', this.onDocumentDrop, false)

          this.dropElement.removeEventListener('dragenter', this.onDragenter, false)
          this.dropElement.removeEventListener('dragleave', this.onDragleave, false)
          this.dropElement.removeEventListener('dragover', this.onDragover, false)
          this.dropElement.removeEventListener('drop', this.onDrop, false)
        } catch (e) {
        }
      }

      let el: HTMLElement | null = null

      if (!newDrop) {
        // empty
      } else if (typeof newDrop === 'string') {
        // @ts-ignore
        el = document.querySelector(newDrop) || this.$root.$el.querySelector(newDrop)
      } else if (newDrop === true) {
        // @ts-ignore
        el = this.$parent.$el
        if (!el || el?.nodeType === 8) {
          // @ts-ignore
          el = this.$root.$el
          if (!el || el?.nodeType === 8) {
            el = document.body
          }
        }
      } else {
        el = newDrop
      }
      this.dropElement = el

      if (this.dropElement) {
        document.addEventListener('dragenter', this.onDocumentDragenter, false)
        document.addEventListener('dragleave', this.onDocumentDragleave, false)
        document.addEventListener('dragover', this.onDocumentDragover, false)
        document.addEventListener('drop', this.onDocumentDrop, false)

        this.dropElement.addEventListener('dragenter', this.onDragenter, false)
        this.dropElement.addEventListener('dragleave', this.onDragleave, false)
        this.dropElement.addEventListener('dragover', this.onDragover, false)
        this.dropElement.addEventListener('drop', this.onDrop, false)
      }
    },

    watchDropActive(newDropActive: boolean, oldDropActive?: boolean) {
      if (newDropActive === oldDropActive) {
        return
      }

      // 设置 dropElementActive false
      if (!newDropActive && this.dropElementActive) {
        this.dropElementActive = false
      }

      if (this.dropTimeout) {
        clearTimeout(this.dropTimeout)
        this.dropTimeout = null
      }

      if (newDropActive) {
        // @ts-ignore
        this.dropTimeout = setTimeout(this.onDocumentDrop, 1000);
      }

    },

    onDocumentDragenter(e: DragEvent) {
      if (this.dropActive) {
        return
      }
      if (!e.dataTransfer) {
        return
      }
      const dt = e.dataTransfer
      if (dt?.files?.length) {
        this.dropActive = true
      } else if (!dt.types) {
        this.dropActive = true
      } else if (dt.types.indexOf && dt.types.indexOf('Files') !== -1) {
        this.dropActive = true
        // @ts-ignore
      } else if (dt.types?.contains && dt.types.contains('Files')) {
        this.dropActive = true
      }
      if (this.dropActive) {
        this.watchDropActive(true)
      }
    },

    onDocumentDragleave(e: DragEvent) {
      if (!this.dropActive) {
        return
      }

      // @ts-ignore
      if (e.target === e.explicitOriginalTarget || (!e.fromElement && (e.clientX <= 0 || e.clientY <= 0 || e.clientX >= window.innerWidth || e.clientY >= window.innerHeight))) {
        this.dropActive = false
        this.watchDropActive(false)
      }
    },

    onDocumentDragover() {
      this.watchDropActive(true)
    },

    onDocumentDrop() {
      this.dropActive = false
      this.watchDropActive(false)
    },

    onDragenter(e: DragEvent) {
      if (!this.dropActive || this.dropElementActive) {
        return
      }
      this.dropElementActive = true
    },

    onDragleave(e: DragEvent) {
      if (!this.dropElementActive) {
        return
      }

      const related = e.relatedTarget as ParentNode | null;


      if (!related) {
        this.dropElementActive = false
      } else if (this.dropElement?.contains) {
        if (!this.dropElement.contains(related)) {
          this.dropElementActive = false
        }
      } else {
        let child = related
        while (child) {
          if (child === this.dropElement) {
            break
          }
          // @ts-ignore
          child = child.parentNode;
        }
        if (child !== this.dropElement) {
          this.dropElementActive = false
        }
      }
    },

    onDragover(e: DragEvent) {
      e.preventDefault()
    },

    onDrop(e: DragEvent) {
      e.preventDefault()
      e.dataTransfer && this.addDataTransfer(e.dataTransfer)
    },


    async inputOnChange(e: Event) {
      if (!(e.target instanceof HTMLInputElement)) {
        return Promise.reject(new Error("not HTMLInputElement"))
      }
      const target = e.target
      const reinput = (res: any) => {
        this.reload = true
        // @ts-ignore
        this.$nextTick(() => {
          this.reload = false
        })
        return res
      }

      return this.addInputFile(e.target).then(reinput).catch(reinput)
    },

    isRelatedTargetSupported() {
      try {
        // 创建一个模拟的 MouseEvent
        const event = new MouseEvent('mouseout', {
          relatedTarget: document.body
        });
        return 'relatedTarget' in event; // 检查 `relatedTarget` 属性是否存在
      } catch (e) {
        // 如果 MouseEvent 不受支持，或者无法设置 relatedTarget
        return false;
      }
    },
  },
})
</script>
