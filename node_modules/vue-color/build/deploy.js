var ghpages = require('gh-pages')
var path = require('path')

ghpages.publish(path.join(__dirname, '../example-dist'), function (err) {
  if (err) {
    console.log(err)
  } else {
    console.log('publish to github page done')
  }
})
