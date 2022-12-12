import Vue from 'vue'
import marked from 'marked'
import highlightjs from 'highlight.js'
import store from './store'
import router from './router'
import i18n from './i18n'
import App from './views/App'

Vue.config.silent = false
Vue.config.devtools = true


class Renderer extends marked.Renderer {
  heading(text, level, raw) {
    let rawName = raw.toLowerCase().replace(/([\u0000-\u002F\u003A-\u0060\u007B-\u007F]+)/g, '-').replace(/^\-+|\-+$/, '')

    if (!this.options.headers) {
      this.options.headers = []
    }
    while (this.options.headers.length >= level) {
      this.options.headers.pop()
    }
    let parent = this.options.headers.filter(value => !!value).join('-')
    if (parent) {
      parent = parent + '-'
    }
    while (this.options.headers.length < (level - 1)) {
      this.options.headers.push('')
    }
    this.options.headers.push(rawName)
    return '<h'
    + level
    + ' id="'
    + this.options.headerPrefix
    + parent
    + rawName
    + '">'
    + text
    + '</h'
    + level
    + '>\n'
  }
}

marked.setOptions({
  renderer: new Renderer(),
  gfm: true,
  tables: true,
  breaks: false,
  pedantic: false,
  sanitize: false,
  smartLists: true,
  smartypants: false,
  highlight(code, lang) {
    if (lang) {
      return highlightjs.highlight(lang, code).value
    } else {
      return highlightjs.highlightAuto(code).value
    }
  }
})

Vue.directive('markdown', function (el, binding, vnode) {
  if (!el.className || !/vue-markdown/.test(el.className)) {
    el.className += ' vue-markdown'
  }
  let text = ''
  for (let i = 0; i < vnode.children.length; i++) {
    text += vnode.children[i].text || ''
  }
  if (el.markdown === text) {
    return
  }

  el.markdown = text

  el.innerHTML = marked(text)
  let selectorList = el.querySelectorAll('a')
  for (let i = 0; i < selectorList.length; i++) {
    selectorList[i].onclick = function (e) {
      if (e.metaKey || e.ctrlKey || e.shiftKey) {
        return
      }
      if (e.defaultPrevented) {
        return
      }
      if (e.button !== undefined && e.button !== 0) {
        return
      }

      if (this.host !== window.location.host) {
        return
      }

      let href = this.getAttribute('href')
      if (!href) {
        return
      }

      if (href.charAt(0) !== '#') {
        return
      }

      e.preventDefault()
      router.push(href)
    }
  }
})



Vue.filter('formatSize', function (size) {
  if (size > 1024 * 1024 * 1024 * 1024) {
    return (size / 1024 / 1024 / 1024 / 1024).toFixed(2) + ' TB'
  } else if (size > 1024 * 1024 * 1024) {
    return (size / 1024 / 1024 / 1024).toFixed(2) + ' GB'
  } else if (size > 1024 * 1024) {
    return (size / 1024 / 1024).toFixed(2) + ' MB'
  } else if (size > 1024) {
    return (size / 1024).toFixed(2) + ' KB'
  }
  return size.toString() + ' B'
})

Vue.filter('toLocale', function (to) {
  return '/' + i18n.locale + to
})



new Vue({
  store,
  router,
  i18n,
  ...App
}).$mount('#app')
