const md = require('markdown-it')()
const anchor = require('markdown-it-anchor')

md.use(anchor, {
  level: 1,
  // slugify: string => string,
  permalink: false,
  // renderPermalink: (slug, opts, state, permalink) => {},
  permalinkClass: 'header-anchor',
  permalinkSymbol: '¶',
  permalinkBefore: false
})

const src = `# First header

Lorem ipsum.

## Next section!

This is totaly awesome.`

console.log(md.render(src))
