const { join, normalize } = require('path')
const { source_path: sourcePath, static_assets_extensions: fileExtensions } = require('../config')

module.exports = {
  test: new RegExp(`(${fileExtensions.join('|')})$`, 'i'),
  use: [
    {
      loader: 'file-loader',
      options: {
        name(file) {
          if (file.includes(normalize(sourcePath))) {
            return 'media/[path][name]-[hash].[ext]'
          }
          return 'media/[folder]/[name]-[hash:8].[ext]'
        },
        esModule: false,
        context: join(sourcePath)
      }
    }
  ]
}
