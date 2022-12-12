## 入门开始

### NPM

``` bash
npm install vue-upload-component --save
```

``` js
const VueUploadComponent = require('vue-upload-component')
Vue.component('file-upload', VueUploadComponent)
```

### Curated

**No data**


### 直接使用


unpkg

``` html
<script src="https://unpkg.com/vue"></script>
<script src="https://unpkg.com/vue-upload-component"></script>
<script>
Vue.component('file-upload', VueUploadComponent)
</script>
```

jsDelivr

``` html
<script src="https://cdn.jsdelivr.net/npm/vue/dist/vue.js"></script>
<script src="https://cdn.jsdelivr.net/npm/vue-upload-component"></script>
<script>
Vue.component('file-upload', VueUploadComponent)
</script>
```


### 简单的例子



```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Vue-upload-component Test</title>
  <script src="https://unpkg.com/vue"></script>
  <script src="https://unpkg.com/vue-upload-component"></script>
</head>
<body>
<div id="app">
  <ul>
    <li v-for="file in files">{{file.name}} - Error: {{file.error}}, Success: {{file.success}}</li>
  </ul>
  <file-upload
    ref="upload"
    v-model="files"
    post-action="/post.method"
    put-action="/put.method"
    @input-file="inputFile"
    @input-filter="inputFilter"
  >
  上传文件
  </file-upload>
  <button v-show="!$refs.upload || !$refs.upload.active" @click.prevent="$refs.upload.active = true" type="button">开始上传</button>
  <button v-show="$refs.upload && $refs.upload.active" @click.prevent="$refs.upload.active = false" type="button">停止上传</button>
</div>
<script>
new Vue({
  el: '#app',
  data: function () {
    return {
      files: []
    }
  },
  components: {
    FileUpload: VueUploadComponent
  },
  methods: {
    /**
     * Has changed
     * @param  Object|undefined   newFile   只读
     * @param  Object|undefined   oldFile   只读
     * @return undefined
     */
    inputFile: function (newFile, oldFile) {
      if (newFile && oldFile && !newFile.active && oldFile.active) {
        // 获得相应数据
        console.log('response', newFile.response)
        if (newFile.xhr) {
          //  获得响应状态码
          console.log('status', newFile.xhr.status)
        }
      }
    },
    /**
     * Pretreatment
     * @param  Object|undefined   newFile   读写
     * @param  Object|undefined   oldFile   只读
     * @param  Function           prevent   阻止回调
     * @return undefined
     */
    inputFilter: function (newFile, oldFile, prevent) {
      if (newFile && !oldFile) {
        // 过滤不是图片后缀的文件
        if (!/\.(jpeg|jpe|jpg|gif|png|webp)$/i.test(newFile.name)) {
          return prevent()
        }
      }

      // 创建 blob 字段 用于图片预览
      newFile.blob = ''
      let URL = window.URL || window.webkitURL
      if (URL && URL.createObjectURL) {
        newFile.blob = URL.createObjectURL(newFile.file)
      }
    }
  }
});
</script>
</body>
</html>
```



### SSR (服务器同构)


```html
<template>
  <file-upload v-model="files" post-action="/">Upload file</file-upload>
</template>
<style>
/*
import '~vue-upload-component/dist/vue-upload-component.part.css'
@import "~vue-upload-component/dist/vue-upload-component.part.css";

或


 */
.file-uploads {
  overflow: hidden;
  position: relative;
  text-align: center;
  display: inline-block;
}
.file-uploads.file-uploads-html4 input[type="file"] {
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
.file-uploads.file-uploads-html5 input[type="file"] {
  overflow: hidden;
  position: fixed;
  width: 1px;
  height: 1px;
  z-index: -1;
  opacity: 0;
}
</style>
<script>
import FileUpload from 'vue-upload-component/dist/vue-upload-component.part.js'
export default {
  components: {
    FileUpload,
  },
  data() {
    return {
      files: []
    }
  },
}
</script>
```


** 或者 **


```js
import FileUpload from 'vue-upload-component/src'
```

webpack.config.js

```js
const nodeExternals = require('webpack-node-externals');
{
  //...
  externals: [
    nodeExternals({whitelist:[/^vue-upload-component\/src/]})
  ]
  //...
}
```

* [https://github.com/liady/webpack-node-externals](https://github.com/liady/webpack-node-externals)  

* [**`vue-hackernews` 演示**](https://github.com/lian-yue/vue-hackernews-2.0/)  

* [**浏览修改文件**](https://github.com/lian-yue/vue-hackernews-2.0/commit/bd6c58a30cc6b8ba6c0148e737b3ce9336b99cf8)




## 选项 / 属性


### input-id

input 标签的 `id` 属性

* **类型:** `String`

* **默认值:** `this.name`

* **示例:**
  ```html
  <file-upload input-id="file2"></file-upload>
  <!--输出-->
  <input id="file2" />
  ```





### name

input标签的 `name` 属性

* **类型:** `String`

* **默认值:** `file`

* **示例:**
  ```html
  <file-upload name="file"></file-upload>
  <!--输出-->
  <input name="file" />
  ```





### post-action

`POST` 请求的上传URL

* **类型:** `String`

* **默认值:** `undefined`

* **示例:**
  ```html
  <file-upload post-action="/upload/post.php"></file-upload>
  ```





### put-action

`PUT` 请求的上传URL

* **类型:** `String`

* **默认值:** `undefined`

* **浏览器:** `> IE9`

* **详细:**  

  `put-action` 不为空请优先 `PUT` 请求  

* **示例:**
  ```html
  <file-upload put-action="/upload/put.php"></file-upload>
  ```



### custom-action

自定义上传方法

* **类型:** `async Function`

* **默认值:** `undefined`

* **详细:**  

  `custom-action` 优先级高于 `put-action, post-action`

* **示例:**
  ```html
  <file-upload :custom-action="customAction"></file-upload>
  ```
  ```js
  async function customAction(file, component) {
    // return await component.uploadPut(file)
    return await component.uploadHtml4(file)
  }
  ```



### headers

自定义上传请求 `header` 数据

* **类型:** `Object`

* **默认值:** `{}`

* **浏览器:** `> IE9`

* **示例:**
  ```html
  <file-upload :headers="{'X-Token-CSRF': 'code'}"></file-upload>
  ```





### data

`POST 请求`: 附加请求的 body  
`PUT 请求`: 附加请求的 query  

* **类型:** `Object`

* **默认值:** `{}`

* **示例:**
  ```html
  <file-upload :data="{access_token: 'access_token'}"></file-upload>
  ```




### value, v-model

文件列表

* **类型:** `Array<File | Object>`

* **默认值:** `[]`

* **详细:**  

  浏览 **[`File`](#file)** 详细信息  
  > 为了防止不可预知的错误，不可直接修改 `files`，请使用 [`add`](#实例-方法-add), [`update`](#实例-方法-update), [`remove`](#实例-方法-remove) 方法修改

* **示例:**
  ```html
  <file-upload :value="files" @input="updatetValue"></file-upload>
  <!--或-->
  <file-upload v-model="files"></file-upload>
  ```





### accept

表单的`accept`属性, MIME type  

* **类型:** `String`

* **默认值:** `undefined`

* **浏览器:** `> IE9`

* **示例:**
  ```html
  <file-upload accept="image/png,image/gif,image/jpeg,image/webp"></file-upload>
  <!--或-->
  <file-upload accept="image/*"></file-upload>
  ```





### multiple

文件表单的 `multiple` 属性  
是否允许选择多个文件  

* **类型:** `Boolean`

* **默认值:** `false`

* **详细:**  

  如果是 `false` `files` 里面最多只有一个文件 多的会自动删除  

* **示例:**
  ```html
  <file-upload :multiple="true"></file-upload>
  ```



### directory

文件表单的 `directory` 属性  
是否是上传文件夹  

* **类型:** `Boolean`

* **默认值:** `false`

* **浏览器:** [http://caniuse.com/#feat=input-file-directory](http://caniuse.com/#feat=input-file-directory)

* **示例:**
  ```html
  <file-upload :directory="true" :multiple="true"></file-upload>
  ```





### extensions

允许上传的文件后缀

* **类型:** `Array | String | RegExp`

* **默认值:** `undefined`

* **示例:**
  ```html
  <file-upload extensions="jpg,gif,png,webp"></file-upload>
  <!--或-->
  <file-upload :extensions="['jpg', 'gif', 'png', 'webp']"></file-upload>
  <!--或-->
  <file-upload :extensions="/\.(gif|jpe?g|png|webp)$/i"></file-upload>
  ```




### size

允许上传的最大字节

* **类型:** `Number`

* **默认值:** `0`

* **浏览器:** `> IE9`

* **详细:**

  `0` 等于不限制

* **示例:**
  ```html
  <file-upload :size="1024 * 1024"></file-upload>
  ```




### timeout

上传超时时间毫秒

* **类型:** `Number`

* **默认值:** `0`

* **浏览器:** `> IE9`

* **示例:**
  ```html
  <file-upload :timeout="600 * 1000"></file-upload>
  ```


### maximum

列表最大文件数

* **类型:** `Number`

* **默认值:** `props.multiple ? 0 : 1`

* **示例:**
  ```html
  <file-upload :maximum="10"></file-upload>
  ```




### thread

同时并发上传的文件数量 线程数  

* **类型:** `Number`

* **默认值:** `1`

* **浏览器:** `> IE9`

* **示例:**
  ```html
  <file-upload :thread="3"></file-upload>
  ```





### drop

拖拽上传  

* **类型:** `Boolean | Element | CSS selector`

* **默认值:** `false`

* **浏览器:** [http://caniuse.com/#feat=dragndrop](http://caniuse.com/#feat=dragndrop)

* **详细:**

  如果设置成 `true` 则读取父组件作为容器  

* **示例:**
  ```html
  <file-upload :drop="true"></file-upload>
  ```





### drop-directory

是否开启拖拽目录  

* **类型:** `Boolean`

* **默认值:** `true`

* **详细:**

  如果设置成 `false` 则过滤掉目录

* **示例:**
  ```html
  <file-upload :drop-directory="false"></file-upload>
  ```


### add-index

* **类型:** `Boolean, Number`

* **默认值:** `undefined`

* **版本:** `>= 2.6.1`

* **详细:**

  [`add()`](#实例-方法-add) 方法 `index` 参数的默认值

* **示例:**
  ```html
  <file-upload :add-index="true"></file-upload>
  ```



## 选项 / 事件

文件被改变触发的方法  
默认用于`v-model`绑定

### @input
* **参数:**

  * `files: Array<File | Object>`


* **示例:**
  ```html
  <template>
    <file-upload :value="files" @input="updatetValue"></file-upload>
    <!--或者-->
    <file-upload v-model="files"></file-upload>
  </template>
  <script>
  export default {
    data() {
      return {
        files: []
      }
    },
    methods: {
      updatetValue(value) {
        this.files = value
      }
    }
  }
  </script>
  ```



### @input-filter

Add, update, remove pre-filter  

* **参数:**

  * `newFile: File | Object | undefined`  `读写`
  * `oldFile: File | Object | undefined`  `只读`
  * `prevent: Function`   调用该方法 阻止修改


* **详细:**

  如果 `newFile` 值为 `undefined` 则是删除  
  如果 `oldFile` 值为 `undefined` 则是添加  
  如果 `newFile`, `oldFile` 都存在则是更新

  > 事件内同步处理请直接修改 `newFile`  
  > 事件内异步处理请使用 `update`, `add`, `remove`, `clear` 方法  
  > 异步请先设置一个错误以防止被上传

  > 同步不能使用 `update`, `add`, `remove`, `clear` 方法  
  > 异步不能修改 `newFile`


* **示例:**  
  ```html
  <template>
    <ul>
      <li v-for="file in files">
        <img :src="file.blob" width="50" height="50" />
      </li>
    </ul>
    <file-upload :value="files" @input-filter="inputFilter"></file-upload>
  </template>
  <script>
  export default {
    data() {
      return {
        files: []
      }
    },
    methods: {
      inputFilter(newFile, oldFile, prevent) {
        if (newFile && !oldFile) {
          // 添加文件

          // 过滤非图片文件
          // 不会添加到 files 去
          if (!/\.(jpeg|jpe|jpg|gif|png|webp)$/i.test(newFile.name)) {
            return prevent()
          }

          // 创建 `blob` 字段 用于缩略图预览
          newFile.blob = ''
          let URL = window.URL || window.webkitURL
          if (URL && URL.createObjectURL) {
            newFile.blob = URL.createObjectURL(newFile.file)
          }
        }

        if (newFile && oldFile) {
          // 更新文件

          // 增加版本号
          if (!newFile.version) {
            newFile.version = 0
          }
          newFile.version++
        }

        if (!newFile && oldFile) {
          // 移除文件

          // 拒绝删除文件
          // return prevent()
        }
      }
    }
  }
  </script>
  ```

### @input-file

添加，更新，移除 后

* **参数:**

  * `newFile: File | Object | undefined` `只读`
  * `oldFile: File | Object | undefined` `只读`


* **详细:**

  如果 `newFile` 值为 `undefined` 则是删除  
  如果 `oldFile` 值为 `undefined` 则是添加  
  如果 `newFile`, `oldFile` 都存在则是更新

  >事件内可使用 `update`, `add`, `remove`, `clear` 方法  
  >事件内不可修改 `newFile` 对象  
  >事件内不可修改 `oldFile` 对象

* **示例:**
  ```html
  <template>
    <file-upload ref="upload" v-model="files" @input-file="inputFile"></file-upload>
  </template>
  <script>
  export default {
    data() {
      return {
        files: []
      }
    },
    methods: {
      inputFile(newFile, oldFile) {
        if (newFile && !oldFile) {
          // 添加文件
        }

        if (newFile && oldFile) {
          // 更新文件

          // 开始上传
          if (newFile.active !== oldFile.active) {
            console.log('Start upload', newFile.active, newFile)

            // 限定最小字节
            if (newFile.size >= 0 && newFile.size < 100 * 1024) {
              newFile = this.$refs.upload.update(newFile, {error: 'size'})
            }
          }

          // 上传进度
          if (newFile.progress !== oldFile.progress) {
            console.log('progress', newFile.progress, newFile)
          }

          // 上传错误
          if (newFile.error !== oldFile.error) {
            console.log('error', newFile.error, newFile)
          }

          // 上传成功
          if (newFile.success !== oldFile.success) {
            console.log('success', newFile.success, newFile)
          }
        }

        if (!newFile && oldFile) {
          // 删除文件

          // 自动删除 服务器上的文件
          if (oldFile.success && oldFile.response.id) {
            // $.ajax({
            //   type: 'DELETE',
            //   url: '/file/delete?id=' + oldFile.response.id,
            // });
          }
        }

        // 自动上传
        if (Boolean(newFile) !== Boolean(oldFile) || oldFile.error !== newFile.error) {
          if (!this.$refs.upload.active) {
            this.$refs.upload.active = true
          }
        }
      }
    }
  }
  </script>
  ```



## 实例 / 数据

### features

用于判断浏览器支持的特性

* **类型:** `Object`

* **只读:** `true`

* **默认值:** `{ html5: true, directory: false, drop: false }`

* **示例:**
  ```html
  <app>
    <file-upload ref="upload"></file-upload>
    <span v-show="$refs.upload && $refs.upload.features.drop">支持拖拽上传</span>
    <span v-show="$refs.upload && $refs.upload.features.directory">支持文件夹上传</span>
    <span v-show="$refs.upload && $refs.upload.features.html5">支持HTML5</span>
  </app>
  ```



### active

激活或停止上传

* **类型:** `Boolean`

* **只读:** `false`

* **默认值:** `false`

* **示例:**
  ```html
  <app>
    <file-upload ref="upload"></file-upload>
    <span v-if="!$refs.upload || !$refs.upload.active" @click="$refs.upload.active = true">开始上传</span>
    <span v-else @click="$refs.upload.active = false">停止上传</span>
  </app>
  ```



### dropActive

是否正在拖拽

* **类型:** `Boolean`

* **只读:** `true`

* **默认值:** `false`

* **示例:**
  ```html
  <app>
    <file-upload ref="upload" :drop="true"></file-upload>
    <span v-show="$refs.upload && $refs.upload.dropActive">拖拽到这里上传</span>
  </app>
  ```





### uploaded

是否全部已上传

* **类型:** `Boolean`

* **只读:** `true`

* **默认值:** `true`

* **示例:**
  ```html
  <app>
    <file-upload ref="upload"></file-upload>
    <span v-show="$refs.upload && $refs.upload.uploaded">全部文件已上传完毕</span>
  </app>
  ```





## 实例 / 方法



### get()

使用`id`获得某个对象

* **参数:**

  * `id: File | Object | String`


* **结果:** `File | Object | Boolean` 存在返回文件对象否则返回 `false`



### add()

添加一个或多个文件

* **参数:**

  * `files: Array<File | window.File | Object> | File | window.File | Object`     如果它是一个数组的响应将是一个数组
  * `index: Number | Boolean` = [`props.add-index`](#选项-属性-add-index)   `true = ` 开始位置, `false = ` 结束位置, `Number = ` 下标位置


* **结果:** `Object | Array<File | Object> | Boolean`     传入的是数组返回数组否则对象或`false`

* **示例:**
  ```html
  <template>
    <ul>
      <li v-for="file in files">
        <span>{{file.name}}</span>
      </li>
    </ul>
    <file-upload v-model="files"></file-upload>
    <button type="button" @click.prevent="addText">添加文件</button>
  </template>
  <script>
  export default {
    data() {
      return {
        files: []
      }
    },
    methods: {
      addText() {
        let file = new window.File(['foo'], 'foo.txt', {
          type: "text/plain",
        })
        this.$refs.upload.add(file)
      }
    }
  }
  </script>
  ```


###  addInputFile()

把`<input type="file">`选择的文件添加进上传列表  

* **参数:**

  * `el: HTMLInputElement`     文件元素


* **结果:** `Array<File>`  返回已添加的文件列表

* **版本:** : `>=2.5.1`



###  addDataTransfer()

把拖拽或者粘贴的数据的文件添加进上传列表  

* **参数:**

  * `dataTransfer: DataTransfer`  拖拽或者粘贴的数据


* **结果:** `Promise<Array<File>>`   返回已添加的文件列表


* **版本:** : `>=2.5.1`



### update()

更新某个对象

* **参数:**

  * `id: File | Object | String`
  * `data: Object`                    更新的数据对象


* **结果:**  `Object | Boolean`  成功返回 `newFile` 失败返回 `false`


* **示例:**
  ```html
  <template>
    <ul>
      <li v-for="file in files">
        <span>{{file.name}}</span>
        <button v-show="file.active" type="button" @click.prevent="abort(file)">停止</button>
      </li>
    </ul>
    <file-upload v-model="files"></file-upload>
  </template>
  <script>
  export default {
    data() {
      return {
        files: []
      }
    },
    methods: {
      abort(file) {
        this.$refs.upload.update(file, {active: false})
        // 或
        // this.$refs.upload.update(file, {error: 'abort'})
      }
    }
  }
  </script>
  ```

### remove()

移除某个文件对象

* **参数:**

  * `id: File | Object | String`


* **结果:**  `Object | Boolean`  成功返回 `oldFile` 失败返回 `false`

* **示例:**
  ```html
  <template>
    <ul>
      <li v-for="file in files">
        <span>{{file.name}}</span>
        <button type="button" @click.prevent="remove(file)">移除</button>
      </li>
    </ul>
    <file-upload v-model="files"></file-upload>
  </template>
  <script>
  export default {
    data() {
      return {
        files: []
      }
    },
    methods: {
      remove(file) {
        this.$refs.upload.remove(file)
      }
    }
  }
  </script>
  ```


### replace()
  替换两个文件的位置

* **参数:**

  * `id1: File | Object | String`
  * `id2: File | Object | String`


* **结果:**  `Boolean`



### clear()

清空文件列表

* **结果:**  `Boolean`  总是返回 `true`



## 实例 / File


> **文件对象在`input-filter`事件外修改请使用 [`update`](#实例-方法-update) 方法**


### fileObject

* **类型:** `Boolean`

* **只读:** `true`

* **Required:** `true`

* **默认值:** `true`

* **版本:** : `>=2.6.0`

* **详细:**

  如果属性不存在，则不会在内部处理该对象  
  如果属性不存在，它不是 `File` 而是 `Object`



### id

文件id

* **类型:** `String | Number`

* **只读:** `false`

* **默认值:** `Math.random().toString(36).substr(2)`

* **详细:**

  >`id` can not be repeated  
  >Upload can not modify `id`


### size

文件大小

* **类型:** `Number`

* **只读:** `false`

* **默认值:** `-1`

* **浏览器:** `> IE9`


### name

文件名  

* **类型:** `String`

* **只读:** `false`

* **默认值:** ` `

* **详细:**

  格式:  `directory/filename.gif`  `filename.gif`  



### type

MIME类型

* **类型:** `String`

* **只读:** `false`

* **默认值:** ` `

* **浏览器:** `> IE9`

* **详细:**

  格式:  `image/gif`   `image/png`  `text/html`




### active

激活或终止上传

* **类型:** `Boolean`

* **只读:** `false`

* **默认值:** `false`

* **详细:**

  `true` = 上传  
  `false` = 停止  






### error

上传失败错误代码

* **类型:** `String`

* **只读:** `false`

* **默认值:** ` `

* **详细:**

  内置
  `size`, `extension`, `timeout`, `abort`, `network`, `server`, `denied`




### success

是否上传成功

* **类型:** `Boolean`

* **只读:** `false`

* **默认值:** `false`


### putAction

自定义当前文件 `PUT` 地址

* **类型:** `String`

* **只读:** `false`

* **默认值:** `this.putAction`



### postAction

自定义当前文件 `POST` 地址

* **类型:** `String`

* **只读:** `false`

* **默认值:** `this.postAction`




### headers

自定义当前文件 `HTTP` Header

* **类型:** `Object`

* **只读:** `false`

* **默认值:** `this.headers`


### data

自定义当前文件 `body` 或 `query` 附加内容

* **类型:** `Object`

* **只读:** `false`

* **默认值:** `this.data`


### timeout

自定义当前单个文件的上传超时时间

* **类型:** `Number`

* **只读:** `false`

* **默认值:** `this.timeout`


### response

响应的数据

* **类型:** `Object | String`

* **只读:** `false`

* **默认值:** `{}`




### progress

上传进度

* **类型:** `String`

* **只读:** `false`

* **默认值:** `0.00`

* **浏览器:** `> IE9`



### speed

每秒的上传速度

* **类型:** `Number`

* **只读:** `true`

* **默认值:** `0`

* **浏览器:** `> IE9`




### xhr

`HTML5` 上传 `XMLHttpRequest` 对象

* **类型:** `XMLHttpRequest`

* **只读:** `true`

* **默认值:** `undefined`

* **浏览器:** `> IE9`




### iframe

`HTML4` 上传 `iframe` 元素

* **类型:** `Element`

* **只读:** `true`

* **默认值:** `undefined`

* **浏览器:** `= IE9`
