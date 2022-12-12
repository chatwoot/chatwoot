<template>
  <div class="specimens specimens--text">
    <h2>File classification</h2>
    <div class="specimen">
      <h3>Single File</h3>
      <FormulateInput
        label="Upload a file"
        type="file"
        :outer-class="['file-input-1']"
        help="Select any file to upload"
        :uploader="uploadToS3"
        upload-url="https://cq2cm6d0h6.execute-api.us-east-1.amazonaws.com/signature"
      />
    </div>
    <div class="specimen">
      <h3>Multiple Files</h3>
      <FormulateInput
        :multiple="true"
        label="Upload a file"
        name="file"
        type="file"
        :outer-class="['file-input-2']"
        :value="[{ url: 'apple.pdf' }]"
        help="Select any file to upload"
        validation="mime:application/pdf"
      />
    </div>
    <div class="specimen">
      <h3>Image</h3>
      <FormulateInput
        label="What do you look like?"
        type="image"
        help="Select a picture to upload."
        multiple
      />
    </div>
  </div>
</template>

<script>
export default {
  methods: {
    async uploadToS3 (file, progress, error, options) {
      const matches = file.name.match(/\.([a-zA-Z0-9]+)$/)
      const extension = (matches) ? matches[1] : 'txt'
      progress(5)
      const response = await fetch(options.uploadUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          extension,
          mime: file.type || 'application/octet-stream'
        })
      })
      if (response.ok) {
        const { uploadUrl } = await response.json()
        progress(10)
        const xhr = new XMLHttpRequest()
        xhr.open('PUT', uploadUrl)
        xhr.upload.addEventListener('progress', e => progress(Math.round(e.loaded / e.total * 90) + 10))
        xhr.setRequestHeader('Content-Type', 'application/octet-stream')
        try {
          await new Promise((resolve, reject) => {
            xhr.onload = e => (xhr.status - 200) < 100 ? resolve() : reject(new Error('Failed to upload'))
            xhr.onerror = e => reject(new Error('Failed to upload'))
            xhr.send(file)
          })
          progress(100)
          const url = new URL(uploadUrl)
          return {
            url: `${url.protocol}//${url.host}${url.pathname}`,
            name: file.name
          }
        } catch {
          // we'll suppress this since we have a catch all error
        }
      }
      // Catch all error
      error('There was an error uploading your file.')
    }
  }
}
</script>
