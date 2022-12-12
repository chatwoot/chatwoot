
> **The document uses Google Translate**

## Getting Started

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


### Script


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


### Simple example



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
  Upload file
  </file-upload>
  <button v-show="!$refs.upload || !$refs.upload.active" @click.prevent="$refs.upload.active = true" type="button">Start upload</button>
  <button v-show="$refs.upload && $refs.upload.active" @click.prevent="$refs.upload.active = false" type="button">Stop upload</button>
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
     * @param  Object|undefined   newFile   Read only
     * @param  Object|undefined   oldFile   Read only
     * @return undefined
     */
    inputFile: function (newFile, oldFile) {
      if (newFile && oldFile && !newFile.active && oldFile.active) {
        // Get response data
        console.log('response', newFile.response)
        if (newFile.xhr) {
          //  Get the response status code
          console.log('status', newFile.xhr.status)
        }
      }
    },
    /**
     * Pretreatment
     * @param  Object|undefined   newFile   Read and write
     * @param  Object|undefined   oldFile   Read only
     * @param  Function           prevent   Prevent changing
     * @return undefined
     */
    inputFilter: function (newFile, oldFile, prevent) {
      if (newFile && !oldFile) {
        // Filter non-image file
        if (!/\.(jpeg|jpe|jpg|gif|png|webp)$/i.test(newFile.name)) {
          return prevent()
        }
      }

      // Create a blob field
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

### Chunk Upload

This package allows chunk uploads, which means you can upload a file in different parts.

This process is divided in three phases: <strong>start</strong>, <strong>upload</strong>,<strong>finish</strong></p>

#### start

This is the first phase of the process. We'll tell the backend that we are going to upload a file, with certain `size`, `name` and `mime_type`.

Use the option `startBody` to add more parameters to the body of this request.

The backend should provide a `session_id` (to identify the upload) and a `end_offset` which is the size of every chunk

##### HTTP start phase example

Request body example:
```
{
  "phase": "start",
  "mime_type": "image/png",
  "size": 12669430,
  "name":"hubbleimage1stscihp1809af6400x4800.png"
}
```

Response body example:
```
{
  "data": {
    "end_offset": 6291456,
    "session_id": "61db8102-fca6-44ae-81e2-a499d438e7a5"
  },
  "status": "success"
}

```

#### upload

In this phase we'll upload every chunk until all of them are uploaded. This step allows some failures in the backend, and will retry up to `maxRetries` times.

We'll send the `session_id`, `start_offset` and `chunk` (the sliced blob - part of file we are uploading). We expect the backend to return `{ status: 'success' }`, we'll retry otherwise.

Use the option `uploadBody` to add more parameters to the body of this request.

##### HTTP upload phase example with 3 chunks

Request body example - chunk 1 from 3:
```
------WebKitFormBoundaryuI0uiY8h7MCbcysx
Content-Disposition: form-data; name="phase"

upload
------WebKitFormBoundaryuI0uiY8h7MCbcysx
Content-Disposition: form-data; name="session_id"

61db8102-fca6-44ae-81e2-a499d438e7a5
------WebKitFormBoundaryuI0uiY8h7MCbcysx
Content-Disposition: form-data; name="start_offset"

0
------WebKitFormBoundaryuI0uiY8h7MCbcysx
Content-Disposition: form-data; name="chunk"; filename="blob"
Content-Type: application/octet-stream


------WebKitFormBoundaryuI0uiY8h7MCbcysx--
```

Response body example - chunk 1 from 3:
```
{
  "status": "success"
}
```

Request body example - chunk 2 from 3:
```
------WebKitFormBoundary4cjBupFqrx1SrHoR
Content-Disposition: form-data; name="phase"

upload
------WebKitFormBoundary4cjBupFqrx1SrHoR
Content-Disposition: form-data; name="session_id"

61db8102-fca6-44ae-81e2-a499d438e7a5
------WebKitFormBoundary4cjBupFqrx1SrHoR
Content-Disposition: form-data; name="start_offset"

6291456
------WebKitFormBoundary4cjBupFqrx1SrHoR
Content-Disposition: form-data; name="chunk"; filename="blob"
Content-Type: application/octet-stream


------WebKitFormBoundary4cjBupFqrx1SrHoR-
```

Response body example - chunk 2 from 3:
```
{
  "status": "success"
}
```

Request body example - chunk 3 from 3:
```
------WebKitFormBoundarypWxg4xnB5QBDoFys
Content-Disposition: form-data; name="phase"

upload
------WebKitFormBoundarypWxg4xnB5QBDoFys
Content-Disposition: form-data; name="session_id"

61db8102-fca6-44ae-81e2-a499d438e7a5
------WebKitFormBoundarypWxg4xnB5QBDoFys
Content-Disposition: form-data; name="start_offset"

12582912
------WebKitFormBoundarypWxg4xnB5QBDoFys
Content-Disposition: form-data; name="chunk"; filename="blob"
Content-Type: application/octet-stream


------WebKitFormBoundarypWxg4xnB5QBDoFys--
```

Response body example - chunk 1 from 3:
```
{
  "status": "success"
}
```

#### finish

In this phase we tell the backend that there are no more chunks to upload, so it can wrap everything. We send the `session_id` in this phase.

Use the option `finishBody` to add more parameters to the body of this request.

##### HTTP finish phase example

Request body example:
```
{
  "phase": "finish",
  "session_id": "61db8102-fca6-44ae-81e2-a499d438e7a5"
}
```

Response body example:
```
{
  "status": "success"
}
```

#### Example

In the following example we are going to add `Chunk Upload Functionality`. This component will use `Chunk Upload` when the size of the file is > `1MB`, it will behave as the `Simple example` when the size of the file is lower.

```html
  <file-upload
    ref="upload"
    v-model="files"
    post-action="/post.method"
    put-action="/put.method"

    chunk-enabled
    :chunk="{
      action: '/upload/chunk',
      minSize: 1048576,
      maxActive: 3,
      maxRetries: 5,

      // Example in the case your backend also needs the user id to operate
      startBody: {
        user_id: user.id
      }
    }"

    @input-file="inputFile"
    @input-filter="inputFilter"
  >
  Upload file
  </file-upload>
```

#### Extending the handler

We are using the class `src/chunk/ChunkUploadHandler` class to implement this protocol. You can extend this class (or even create a different one from scratch) to implement your own way to communicat with the backend.

This class must implement a method called `upload` which **must** return a promise. This promise will be used by the `FileUpload` component to determinate whether the file was uploaded or failed.

Use the `handler` parameter to use a different Handler

```html
 :chunk="{
   action: '/upload/chunk',
   minSize: 1048576,
   maxActive: 3,
   maxRetries: 5,

   handler: MyHandlerClass
 }
```

### SSR (Server isomorphism)


```html
<template>
  <file-upload v-model="files" post-action="/">Upload file</file-upload>
</template>
<style>
/*
import '~vue-upload-component/dist/vue-upload-component.part.css'
@import "~vue-upload-component/dist/vue-upload-component.part.css";


or


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


** OR **


```js
import FileUpload from 'vue-upload-component/src'
```


webpack.config.js

```js
const nodeExternals = require('webpack-node-externals');
{
  //.....
  externals: [
    nodeExternals({whitelist:[/^vue-upload-component\/src/]})
  ]
  //.....
}
```

* [https://github.com/liady/webpack-node-externals](https://github.com/liady/webpack-node-externals)

* [**`vue-hackernews` demo**](https://github.com/lian-yue/vue-hackernews-2.0/)

* [**View changes**](https://github.com/lian-yue/vue-hackernews-2.0/commit/bd6c58a30cc6b8ba6c0148e737b3ce9336b99cf8)




## Options / Props


### input-id

The `id` attribute of the input tag

* **Type:** `String`

* **Default:** `this.name`

* **Usage:**
  ```html
  <file-upload input-id="file2"></file-upload>
  <!--Output-->
  <input id="file2" />
  ```





### name

The `name` attribute of the input tag

* **Type:** `String`

* **Default:** `file`

* **Usage:**
  ```html
  <file-upload name="file"></file-upload>
  <!--Output-->
  <input name="file" />
  ```





### post-action

`POST` Request upload URL

* **Type:** `String`

* **Default:** `undefined`

* **Usage:**
  ```html
  <file-upload post-action="/upload/post.php"></file-upload>
  ```





### put-action

`PUT` Request upload URL

* **Type:** `String`

* **Default:** `undefined`

* **Browser:** `> IE9`

* **Details:**

  `put-action` is not empty Please give priority to` PUT` request

* **Usage:**
  ```html
  <file-upload put-action="/upload/put.php"></file-upload>
  ```



### custom-action

Custom upload method

* **Type:** `async Function`

* **Default:** `undefined`

* **Details:**  

  `custom-action` priority than `put-action, post-action`

* **Usage:**
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

Attach `header` data

* **Type:** `Object`

* **Default:** `{}`

* **Browser:** `> IE9`

* **Usage:**
  ```html
  <file-upload :headers="{'X-Token-CSRF': 'code'}"></file-upload>
  ```





### data

`POST request`:  Append request `body`
`PUT request`:  Append request `query`

* **Type:** `Object`

* **Default:** `{}`

* **Usage:**
  ```html
  <file-upload :data="{access_token: 'access_token'}"></file-upload>
  ```




### value, v-model

File List

* **Type:** `Array<File | Object>`

* **Default:** `[]`

* **Details:**

  View **[`File`](#file)** details
  > In order to prevent unpredictable errors, can not directly modify the `files`, please use [`add`](#instance-methods-add), [`update`](#instance-methods-update), [`remove`](#instance-methods-remove) method to modify

* **Usage:**
  ```html
  <file-upload :value="files" @input="updatetValue"></file-upload>
  <!--or-->
  <file-upload v-model="files"></file-upload>
  ```





### accept

The `accept` attribute of the input tag, MIME type

* **Type:** `String`

* **Default:** `undefined`

* **Browser:** `> IE9`

* **Usage:**
  ```html
  <file-upload accept="image/png,image/gif,image/jpeg,image/webp"></file-upload>
  <!--or-->
  <file-upload accept="image/*"></file-upload>
  ```





### multiple

The `multiple` attribute of the input tag
Whether to allow multiple files to be selected

* **Type:** `Boolean`

* **Default:** `false`

* **Details:**

  If it is `false` file inside only one file will be automatically deleted

* **Usage:**
  ```html
  <file-upload :multiple="true"></file-upload>
  ```



### directory

The `directory` attribute of the input tag
Whether it is a upload folder

* **Type:** `Boolean`

* **Default:** `false`

* **Browser:** [http://caniuse.com/#feat=input-file-directory](http://caniuse.com/#feat=input-file-directory)

* **Usage:**
  ```html
  <file-upload :directory="true" :multiple="true"></file-upload>
  ```





### extensions

Allow upload file extensions

* **Type:** `Array | String | RegExp`

* **Default:** `undefined`

* **Usage:**
  ```html
  <file-upload extensions="jpg,gif,png,webp"></file-upload>
  <!--or-->
  <file-upload :extensions="['jpg', 'gif', 'png', 'webp']"></file-upload>
  <!--or-->
  <file-upload :extensions="/\.(gif|jpe?g|png|webp)$/i"></file-upload>
  ```




### size

Allow the maximum byte to upload

* **Type:** `Number`

* **Default:** `0`

* **Browser:** `> IE9`

* **Details:**

  `0` is equal to not limit

* **Usage:**
  ```html
  <file-upload :size="1024 * 1024"></file-upload>
  ```




### timeout

Upload timeout time in milliseconds

* **Type:** `Number`

* **Default:** `0`

* **Browser:** `> IE9`

* **Usage:**
  ```html
  <file-upload :timeout="600 * 1000"></file-upload>
  ```

### maximum

List the maximum number of files

* **Type:** `Number`

* **Default:** `props.multiple ? 0 : 1`

* **Usage:**
  ```html
  <file-upload :maximum="10"></file-upload>
  ```



### thread

Also upload the number of files at the same time (number of threads)

* **Type:** `Number`

* **Default:** `1`

* **Browser:** `> IE9`

* **Usage:**
  ```html
  <file-upload :thread="3"></file-upload>
  ```

### chunk-enabled

Whether chunk uploads is enabled or not

* **Type:** `Boolean`

* **Default:** `false`

* **Usage:**
  ```html
  <file-upload :chunk-enabled="true"></file-upload>
  <file-upload chunk-enabled></file-upload>
  ```

### chunk

All the options to handle chunk uploads

* **Type:** `Object`

* **Default:**
```js
{
    headers: {
      'Content-Type': 'application/json'
    },
    action: '',
    minSize: 1048576,
    maxActive: 3,
    maxRetries: 5,

    // This is the default Handler implemented in this package
    // you can use your own handler if your protocol is different
    handler: ChunkUploadDefaultHandler
}
```

### drop

Drag and drop upload

* **Type:** `Boolean | Element | CSS selector`

* **Default:** `false`

* **Browser:** [http://caniuse.com/#feat=dragndrop](http://caniuse.com/#feat=dragndrop)

* **Details:**

  If set to `true`, read the parent component as a container

* **Usage:**
  ```html
  <file-upload :drop="true"></file-upload>
  ```





### drop-directory

Whether to open the drag directory

* **Type:** `Boolean`

* **Default:** `true`

* **Details:**

  If set to `false` filter out the directory

* **Usage:**
  ```html
  <file-upload :drop-directory="false"></file-upload>
  ```



### add-index

* **Type:** `Boolean, Number`

* **Default:** `undefined`

* **Version:** : `>=2.6.1`

* **Details:**

  The default value of the `index` parameter for the [`add()`](#instance-methods-add) method

* **Usage:**
  ```html
  <file-upload :add-index="true"></file-upload>
  ```




## Options / Events

The files is changed to trigger the method
Default for `v-model` binding

### @input
* **Arguments:**

  * `files: Array<File | Object>`


* **Usage:**
  ```html
  <template>
    <file-upload :value="files" @input="updatetValue"></file-upload>
    <!--or-->
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

* **Arguments:**

  * `newFile: File | Object | undefined`  `Read and write`
  * `oldFile: File | Object | undefined`  `Read only`
  * `prevent: Function`   Call this function to prevent modification


* **Details:**

  If the `newFile` value is `undefined` 'is deleted
  If the `oldFile` value is `undefined` 'is added
  If `newFile`, `oldFile` is exist, it is updated

  > Synchronization modify `newFile`
  > Asynchronous Please use `update`,` add`, `remove`,` clear` method
  > Asynchronous Please set an error first to prevent being uploaded

  > Synchronization can not use `update`,` add`, `remove`,` clear` methods
  > Asynchronous can not modify `newFile`

* **Usage:**
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
          // Add file

          // Filter non-image file
          // Will not be added to files
          if (!/\.(jpeg|jpe|jpg|gif|png|webp)$/i.test(newFile.name)) {
            return prevent()
          }

          // Create the 'blob' field for thumbnail preview
          newFile.blob = ''
          let URL = window.URL || window.webkitURL
          if (URL && URL.createObjectURL) {
            newFile.blob = URL.createObjectURL(newFile.file)
          }
        }

        if (newFile && oldFile) {
          // Update file

          // Increase the version number
          if (!newFile.version) {
            newFile.version = 0
          }
          newFile.version++
        }

        if (!newFile && oldFile) {
          // Remove file

          // Refused to remove the file
          // return prevent()
        }
      }
    }
  }
  </script>
  ```

### @input-file

Add, update, remove after

* **Arguments:**

  * `newFile: File | Object | undefined` `Read only`
  * `oldFile: File | Object | undefined` `Read only`


* **Details:**

  If the `newFile` value is `undefined` 'is deleted
  If the `oldFile` value is `undefined` 'is added
  If `newFile`, `oldFile` is exist, it is updated


  >You can use `update`,` add`, `remove`,` clear` methods in the event
  >You can not modify the `newFile` object in the event
  >You can not modify the `oldFile` object in the event

* **Usage:**
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
          // Add file
        }

        if (newFile && oldFile) {
          // Update file

          // Start upload
          if (newFile.active !== oldFile.active) {
            console.log('Start upload', newFile.active, newFile)

            // min size
            if (newFile.size >= 0 && newFile.size < 100 * 1024) {
              newFile = this.$refs.upload.update(newFile, {error: 'size'})
            }
          }

          // Upload progress
          if (newFile.progress !== oldFile.progress) {
            console.log('progress', newFile.progress, newFile)
          }

          // Upload error
          if (newFile.error !== oldFile.error) {
            console.log('error', newFile.error, newFile)
          }

          // Uploaded successfully
          if (newFile.success !== oldFile.success) {
            console.log('success', newFile.success, newFile)
          }
        }

        if (!newFile && oldFile) {
          // Remove file

          // Automatically delete files on the server
          if (oldFile.success && oldFile.response.id) {
            // $.ajax({
            //   type: 'DELETE',
            //   url: '/file/delete?id=' + oldFile.response.id,
            // });
          }
        }

        // Automatic upload
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



## Instance / Data

### features

Used to determine the browser support features

* **Type:** `Object`

* **Read only:** `true`

* **Default:** `{ html5: true, directory: false, drop: false }`

* **Usage:**
  ```html
  <app>
    <file-upload ref="upload"></file-upload>
    <span v-show="$refs.upload && $refs.upload.features.drop">Support drag and drop upload</span>
    <span v-show="$refs.upload && $refs.upload.features.directory">Support folder upload</span>
    <span v-show="$refs.upload && $refs.upload.features.html5">Support for HTML5</span>
  </app>
  ```



### active

Activation or abort upload

* **Type:** `Boolean`

* **Read only:** `false`

* **Default:** `false`

* **Usage:**
  ```html
  <app>
    <file-upload ref="upload"></file-upload>
    <span v-if="!$refs.upload || !$refs.upload.active" @click="$refs.upload.active = true">Start upload</span>
    <span v-else @click="$refs.upload.active = false">Stop upload</span>
  </app>
  ```



### dropActive

Is dragging

* **Type:** `Boolean`

* **Read only:** `true`

* **Default:** `false`

* **Usage:**
  ```html
  <app>
    <file-upload ref="upload" :drop="true"></file-upload>
    <span v-show="$refs.upload && $refs.upload.dropActive">Drag and drop here for upload</span>
  </app>
  ```





### uploaded

All uploaded

* **Type:** `Boolean`

* **Read only:** `true`

* **Default:** `true`

* **Usage:**
  ```html
  <app>
    <file-upload ref="upload"></file-upload>
    <span v-show="$refs.upload && $refs.upload.uploaded">All files have been uploaded</span>
  </app>
  ```





## Instance / Methods



### get()

Use `id` to get a file object

* **Arguments:**

  * `id: File | Object | String`


* **Result:** `File | Object | Boolean` There is a return file, object that otherwise returns `false`



### add()

Add one or more files

* **Arguments:**

  * `files: Array<File | window.File | Object> | File | window.File | Object`     If it is an array of responses will be an array
  * `index: Number | Boolean` = [`props.add-index`](#options-props-add-index)   `true = ` Start, `false = ` End, `Number = ` Index


* **Result:** `Object | Array<File | Object> | Boolean`     The incoming array is returned to the array otherwise the object or `false`

* **Usage:**
  ```html
  <template>
    <ul>
      <li v-for="file in files">
        <span>{{file.name}}</span>
      </li>
    </ul>
    <file-upload v-model="files"></file-upload>
    <button type="button" @click.prevent="addText">Add a file</button>
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

Add the file selected by `<input type = "file">` to the upload list

* **Arguments:**

  * `el: HTMLInputElement`     File element


* **Result:** `Array<File>`  Added list of files

* **Version:** : `>=2.5.1`



###  addDataTransfer()

Add files that are dragged or pasted into the upload list

* **Arguments:**

  * `dataTransfer: DataTransfer`  Drag or paste data


* **Result:** `Promise<Array<File>>`   Added list of files


* **Version:** : `>=2.5.1`



### update()

Update a file object

* **Arguments:**

  * `id: File | Object | String`
  * `data: Object`                    Updated data object


* **Result:**  `Object | Boolean`  Successfully returned `newFile` failed to return` false`


* **Usage:**
  ```html
  <template>
    <ul>
      <li v-for="file in files">
        <span>{{file.name}}</span>
        <button v-show="file.active" type="button" @click.prevent="abort(file)">Abort</button>
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
        // or
        // this.$refs.upload.update(file, {error: 'abort'})
      }
    }
  }
  </script>
  ```

### remove()

Remove a file object

* **Arguments:**

  * `id: File | Object | String`


* **Result:**  `Object | Boolean`  Successfully returned `oldFile` failed to return` false`

* **Usage:**
  ```html
  <template>
    <ul>
      <li v-for="file in files">
        <span>{{file.name}}</span>
        <button type="button" @click.prevent="remove(file)">Remove</button>
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
  Replace the location of the two files

* **Arguments:**

  * `id1: File | Object | String`
  * `id2: File | Object | String`


* **Result:**  `Boolean`


### clear()

Empty the file list

* **Result:**  `Boolean`  Always return `true`



## Instance / File



> **File object in the `@input-filter` event outside the use of [`update`](#instance-methods-update) method**




### fileObject

* **Type:** `Boolean`

* **Read only:** `true`

* **Required:** `true`

* **Default:** `true`

* **Version:** : `>=2.6.0`

* **Details:**

  If the attribute does not exist, the object will not be processed internally
  If the attribute does not exist, it is not `File` but `Object`




### id

File ID

* **Type:** `String | Number`

* **Read only:** `false`

* **Default:** `Math.random().toString(36).substr(2)`

* **Details:**

  >`id` can not be repeated
  >Upload can not modify `id`


### size

File size

* **Type:** `Number`

* **Read only:** `false`

* **Default:** `-1`

* **Browser:** `> IE9`


### name

Filename

* **Type:** `String`

* **Read only:** `false`

* **Default:** ` `

* **Details:**

  Format:  `directory/filename.gif`  `filename.gif`



### type

MIME type

* **Type:** `String`

* **Read only:** `false`

* **Default:** ` `

* **Browser:** `> IE9`

* **Details:**

  Format:  `image/gif`   `image/png`  `text/html`




### active

Activation or abort upload

* **Type:** `Boolean`

* **Read only:** `false`

* **Default:** `false`

* **Details:**

  `true` = Upload
  `false` = Abort






### error

Upload failed error code

* **Type:** `String`

* **Read only:** `false`

* **Default:** ` `

* **Details:**

  Built-in
  `size`, `extension`, `timeout`, `abort`, `network`, `server`, `denied`




### success

Whether the upload was successful

* **Type:** `Boolean`

* **Read only:** `false`

* **Default:** `false`


### putAction

Customize the current file `PUT` URL

* **Type:** `String`

* **Read only:** `false`

* **Default:** `this.putAction`



### postAction

Customize the current file `POST` URL

* **Type:** `String`

* **Read only:** `false`

* **Default:** `this.postAction`




### headers

Customize the current file `HTTP` Header

* **Type:** `Object`

* **Read only:** `false`

* **Default:** `this.headers`


### data

Customize the current file `body` or` query` to attach content

* **Type:** `Object`

* **Read only:** `false`

* **Default:** `this.data`


### timeout

Customize the upload timeout for a current single file

* **Type:** `Number`

* **Read only:** `false`

* **Default:** `this.timeout`


### response

Response data

* **Type:** `Object | String`

* **Read only:** `false`

* **Default:** `{}`




### progress

Upload progress

* **Type:** `String`

* **Read only:** `false`

* **Default:** `0.00`

* **Browser:** `> IE9`



### speed

Per second upload speed

* **Type:** `Number`

* **Read only:** `true`

* **Default:** `0`

* **Browser:** `> IE9`




### xhr

`HTML5` upload` XMLHttpRequest` object

* **Type:** `XMLHttpRequest`

* **Read only:** `true`

* **Default:** `undefined`

* **Browser:** `> IE9`




### iframe

`HTML4` upload` iframe` element

* **Type:** `Element`

* **Read only:** `true`

* **Default:** `undefined`

* **Browser:** `= IE9`
