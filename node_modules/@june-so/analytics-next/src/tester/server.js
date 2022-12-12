const path = require('path')
const express = require('express')
const port = 3001

const app = express()

app.get('*.js', function (req, res, next) {
  req.url = req.url + '.gz'
  res.set('Content-Encoding', 'gzip')
  res.set('Content-Type', 'text/javascript')
  next()
})
app.use('/', express.static(path.join(__dirname, '__fixtures__')))
app.use('/dist/umd', express.static(path.join(__dirname, '../../dist/umd')))

app.listen(port)
