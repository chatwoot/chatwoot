<template>
<div class="container-fluid">
  <div class="row flex-xl-nowrap">
    <div class="col-12 col-md-3 col-xl-2" id="sidebar">
      <nav id="sidebar-nav" class="collapse show">
        <ul class="nav">
          <li class="nav-item">
            <router-link active-class="active" class="nav-link" :to="'/examples/full' | toLocale">{{$t('example.full')}}</router-link>
          </li>
          <li class="nav-item">
            <router-link active-class="active" class="nav-link" :to="'/examples/simple' | toLocale">{{$t('example.simple')}}</router-link>
          </li>
          <li class="nav-item">
            <router-link active-class="active" class="nav-link" :to="'/examples/avatar' | toLocale">{{$t('example.avatar')}}</router-link>
          </li>
          <li class="nav-item">
            <router-link active-class="active" class="nav-link" :to="'/examples/drag' | toLocale">{{$t('example.drag')}}</router-link>
          </li>
          <li class="nav-item">
            <router-link active-class="active" class="nav-link" :to="'/examples/multiple' | toLocale">{{$t('example.multiple')}}</router-link>
          </li>
          <li class="nav-item">
            <router-link active-class="active" class="nav-link" :to="'/examples/chunk' | toLocale">{{$t('example.chunk')}}</router-link>
          </li>
          <li class="nav-item">
            <router-link active-class="active" class="nav-link" :to="'/examples/vuex' | toLocale">{{$t('example.vuex')}}</router-link>
          </li>
        </ul>
      </nav>
    </div>
    <main class="col-12 col-md-9 col-xl-10 py-md-3 pr-md-5 pl-md-5" id="main" role="main"><router-view></router-view></main>
  </div>
</div>
</template>
