<template>
  <div>
    <header id="header" class="navbar navbar-expand-lg navbar-dark bg-dark">
      <router-link :exact="true" class="navbar-brand"  :to="'/' | toLocale">{{$t('header.logo')}}</router-link>
      <button class="navbar-toggler" type="button" @click.prevent="showNav = !showNav">
        <span class="navbar-toggler-icon"></span>
      </button>
      <nav :class="{collapse: true, 'navbar-collapse': true, show: showNav}" id="navbar">
        <ul class="navbar-nav">
          <li class="nav-item">
            <router-link active-class="active" :exact="true" :class="'nav-link' + ($route.path === '/' ? ' active' : '')"  :to="'/' | toLocale">{{$t('header.home')}}</router-link>
          </li>
          <li class="nav-item">
            <router-link active-class="active" class="nav-link" :to="'/documents' | toLocale">{{$t('header.documents')}}</router-link>
          </li>
          <li class="nav-item">
            <router-link active-class="active" class="nav-link" :to="'/examples' | toLocale">{{$t('header.examples')}}</router-link>
          </li>
          <li class="nav-item">
            <a rel="license noopener" class="nav-link" href="https://www.lianyue.org" target="_blank">{{$t('header.blog')}}</a>
          </li>
        </ul>
        <ul class="navbar-nav ml-md-auto">
          <li class="nav-item dropdown">
            <a class="nav-link dropdown-toggle" href="#" @click.prevent="onLocale(true)" @focus="onLocale(true)" @blur="onLocale(false)">
              {{$t('header.locale')}}
            </a>
            <div :class="{'dropdown-menu': true, show: showLocale}" @blur="onLocale(false)">
              <router-link class="dropdown-item" :to="'/' + name + ($route.params.locale ? $route.fullPath.substr($route.params.locale.length + 1) : $route.fullPath)" v-for="(value, name) in locale" :key="name">{{value}}</router-link>
            </div>
          </li>
          <li class="nav-item">
            <a class="nav-link" href="https://github.com/lian-yue/vue-upload-component/issues">
              {{$t('header.issues')}}
            </a>
          </li>
          <li class="nav-item">
            <a class="nav-link" href="https://github.com/lian-yue/vue-upload-component">
              {{$t('header.github')}}
            </a>
          </li>
        </ul>
      </nav>
    </header>
    <router-view></router-view>
  </div>
</template>
<style>
#header {
  position: -webkit-sticky;
  position: sticky;
  top: 0;
  z-index: 1071;
}
#sidebar {
  background: #fff;
  border-right: 1px solid #e5e5e5;
  border-bottom: 1px solid #e5e5e5;
}

@media (min-width: 768px) {
  #sidebar {
    position: -webkit-sticky;
    position: sticky;
    top: 3.5rem;
    z-index: 1000;
    max-height: calc(100vh - 3.5rem);
    border-right: 1px solid #e5e5e5;
    border-bottom: 1px solid #e5e5e5;
  }
}

#sidebar-nav {
  padding-top: 1rem;
  padding-bottom: 1rem;
  margin-right: -15px;
  margin-left: -15px;
  max-height: 100%;
  overflow-y: auto;
}
#sidebar-nav .nav {
  display: block;
}

#sidebar-nav .nav .nav-item .nav {
  display: none;
  margin-bottom: 1rem;
}
#sidebar-nav .nav .nav-item .nav {
  display: none;
  margin-bottom: 1rem;
}

#sidebar-nav .nav .nav-item.active .nav, #sidebar-nav .nav .active + .nav {
  display: block;
}

@media (min-width: 768px) {
  #sidebar-nav .nav .nav-item .nav {
    display: block;
  }
}

#sidebar-nav .nav .nav-link.active, #sidebar-nav .nav .active > .nav-link{
  color: #262626;
  font-weight: 500;
}

#sidebar-nav .nav-item .nav-link {
  padding: .25rem 1rem;
  font-weight: 500;
  color: #666
}

#sidebar-nav .nav-item .nav-item .nav-link {
  font-weight: 400;
  font-size: 85%;
  margin-left: 1rem
}

#main {
  padding-top: 1rem;
  margin-bottom: 2rem
}


blockquote {
  margin-bottom: 1rem;
  font-size: 1.25rem;
  padding: 0 1em;
  color: #6a737d;
  border-left: 0.25em solid #dfe2e5;
}

pre {
  padding: 16px;
  overflow: auto;
  font-size: 85%;
  line-height: 1.45;
  background-color: #f6f8fa;
  border-radius: 3px;
}

.modal-backdrop.fade {
  visibility: hidden;
}
.modal-backdrop.fade.show {
  visibility: visible;
}

.fade.show {
  display: block;
  z-index: 1072;
}
</style>
<script>
export default {
  data() {
    return {
      showLocale: false,
      showNav: false,
    }
  },
  beforeCreate() {
    if (this.$route.params.locale && this.$route.params.locale !== this.$i18n.locale) {
      this.$i18n.locale = this.$route.params.locale
    }
  },
  beforeUpdate() {
    if (this.$route.params.locale && this.$route.params.locale !== this.$i18n.locale) {
      this.$i18n.locale = this.$route.params.locale
    }
  },
  computed: {
    locale() {
      let i18n = this.$i18n
      return i18n.messages[i18n.locale].locale
    },
  },
  methods: {
    onLocale(show) {
      if (show) {
        this.showLocale = show
      } else {
        setTimeout(() => {
          this.showLocale = show
        }, 128)
      }
    }
  }
}
</script>
