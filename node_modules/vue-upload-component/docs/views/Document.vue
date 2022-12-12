<template>
<div class="container-fluid">
  <div class="row flex-xl-nowrap">
    <div class="col-12 col-md-3 col-xl-2" id="sidebar">
      <nav id="sidebar-nav" class="collapse show">
        <ul class="nav">
          <li :class="{'nav-item': true, active: (!$route.hash && !index) || $route.hash.indexOf(group.hash) === 1}" v-for="(group, index) in navs">
            <router-link active-class="active" :class="{'nav-link': true, active: $route.hash.indexOf(group.hash) === 1}" :to="'#' + group.hash">{{group.name}}</router-link>
            <ul class="nav" v-if="group.children.length">
              <li class="nav-item" v-for="child in group.children">
                <router-link active-class="active" class="nav-link" :to="'#' + group.hash + '-' + child.hash">{{child.name}}</router-link>
              </li>
            </ul>
          </li>
        </ul>
      </nav>
    </div>
    <main class="col-12 col-md-9 col-xl-10 py-md-3 pr-md-5 pl-md-5" id="main" role="main">
      <h1 class="document-title" id="document-title">{{$t('document.title')}}</h1>
      <div class="document-content" v-markdown>{{document}}</div>
    </main>
  </div>
  </div>
</div>
</template>
<style>
.document-title {
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid #ddd;
}
.document-content h2 {
  padding-top: 1rem;
  padding-bottom: 1rem;
  margin-top: 4rem;
  border-bottom: 1px solid #eaecef;
}

.document-content h2:first-child {
  margin-top: 0;
}


.document-content h2 + h3 {
  margin-top: 0rem;
}

.document-content h3 {
  margin-top: 1.5rem;
  padding-top: 1rem;
  margin-bottom: 1rem;
}

</style>
<script>
import marked from 'marked'
export default {

  mounted() {
    // auto scrollTo hash
    if (this.$route.hash) {
      let el = document.querySelector(decodeURIComponent(this.$route.hash))
      if (el) {
        window.scrollTo(0, el.offsetTop)
      }
    }
  },

  computed: {
    document() {
      return require('../docs/' + this.$i18n.locale)
    },

    navs() {
      let tokens = marked.lexer(this.document)
      let rootNode = {
        name: '',
        children: [],
        level: 1,
      }
      let parent = rootNode
      let navPrev
      for (let i = 0; i < tokens.length; i++) {
        let token = tokens[i]
        if (token.type !== 'heading') {
          continue
        }

        let nav = {
          name: token.text,
          hash: token.text.toLowerCase().replace(/([\u0000-\u002F\u003A-\u0060\u007B-\u007F]+)/g, '-').replace(/^\-+|\-+$/, ''),
          level: token.depth,
          children: [],
        }
        if (!navPrev || nav.level === navPrev.level) {
          // empty
        } else if (nav.level > navPrev.level) {
          // next
          parent = navPrev
        } else {
          while (nav.level < navPrev.level && navPrev.parent) {
            navPrev = navPrev.parent
            parent = navPrev.parent
          }
        }

        nav.parent = parent
        parent.children.push(nav)
        navPrev = nav
      }
      return rootNode.children
    },
  },
}
</script>
