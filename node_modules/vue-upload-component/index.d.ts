import Vue from 'vue'

// Instance / File
declare global {
  interface VUFile {
    file: File
    readonly fileObject: boolean
    id: string | number
    size: number
    name: string
    type: string
    active: boolean
    error: string
    success: boolean
    putAction: string
    postAction: string
    headers: object
    data: object
    timeout: number
    response: object | string
    progress: string
    speed: number
    xhr: XMLHttpRequest
    iframe: Element
  }
}

declare class _ extends Vue {
  // Instance / Methods
  get(id: VUFile | object | string): VUFile | object | boolean
  add(files: Array<VUFile | File | object> | VUFile | File | object): object | Array<VUFile | object> | boolean
  addInputFile(el: HTMLInputElement): Array<VUFile>
  addDataTransfer(dataTransfer: DataTransfer): Promise<Array<VUFile>>
  update(id: VUFile | object | string, data: object): object | boolean
  remove(id: VUFile | object | string): object | boolean
  replace(id1: VUFile | object | string, id2: VUFile | object | string): boolean
  clear(): boolean

  // Instance / Data
  readonly files: Array<VUFile>
  readonly features: { html5?: boolean; directory?: boolean; drag?: boolean }
  active: boolean
  readonly dropActive: true
  readonly uploaded: true
}

// module 'vue/types/vue' {
  // https://stackoverflow.com/a/41286276/5221998
  // interface Vue {
  //   readonly $refs: { [key: string]: VueUploadComponent };
  // }
// }

export default _
