const express = require('express')
const path = require('path')
/* eslint-disable new-cap */
const app = new express()
/* eslint-enable new-cap */
const config = require('./config')

const port = process.env.PORT || 3000

app.use(express.static('client'))

/**
 * Note: Generally we don't need an application server for serving
 * static files; instead we can use a web server such as nginx for static resources.
 */
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*')
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept')

  next()
})

app.get('/static/*', (req, res) => {
  res.sendFile(path.join(config.build.assetsRoot, req.path))
})

app.get('*', (req, res) => {
  res.sendFile(config.build.index)
})

app.listen(port, () => {
  console.log(`local server listening on port ${port}`)
})
