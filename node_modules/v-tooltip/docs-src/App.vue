<template>
  <div id="app">
    <header>
      <h1>v-tooltip</h1>
      <div class="command">npm install --save v-tooltip</div>
      <nav>
        <a href="https://github.com/Akryum/vue-tooltip"><img src="https://img.shields.io/github/stars/Akryum/vue-tooltip.svg?style=social&label=Star" /></a>
        <a href="https://www.npmjs.com/package/v-tooltip">
          <img src="https://img.shields.io/npm/v/v-tooltip.svg" />
          <img src="https://img.shields.io/npm/dm/v-tooltip.svg" />
        </a>
        <a href="https://vuejs.org/"><img src="https://img.shields.io/badge/vue-2.0-orange.svg" /></a>
      </nav>
      <div class="description">Customizable &amp; reactive tooltips/popovers/dropdowns with smart positioning</div>
    </header>

    <router-view />

    <section class="more">
      <div class="section-content">
        And much <a href="https://github.com/Akryum/v-tooltip#usage">More</a>!
      </div>
    </section>
  </div>
</template>


<style lang="scss">
body {
  background: white;
  margin: 0;
  font-family: 'Avenir', Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

header {
  background: $primary-color;
  padding: 32px;

  nav,
  .description {
    text-align: center;
  }

  .description {
    color: white;
    margin-top: 24px;
  }
}

section {
  .section-content {
    margin: 0 42px;
    padding: 64px 0;
    box-sizing: border-box;
  }

  &.nav {
    text-align: center;
    background: $primary-color;
    padding: 24px;
    @include h-box;
    @include box-center;

    a {
      display: inline-block;
      padding: 8px 16px;
      color: white;
      background: lighten($primary-color, 10%);
      border-radius: 3px;

      &:hover {
        background: lighten($primary-color, 20%);
      }

      &:not(:last-child) {
        margin-right: 8px;
      }
    }
  }
}

.collapse {
  .section-content {
    padding: 12px 0 64px 0;
  }
}

h1 {
  color: white;
  font-weight: normal;
  text-align: center;
  margin: 0 0 32px;
}

h2 {
  &:first-child {
    margin-top: 0;
  }

  font-weight: normal;
}

a {
  color: $primary-color;
  text-decoration: none;
  cursor: pointer;

  &:hover {
    color: lighten($primary-color, 10%);
  }
}

button,
input {
  font-size: inherit;
  font-family: inherit;
  border: none;
  outline: none;
  padding: 12px 24px;
  border-radius: 2px;
}

button {
  color: $md-grey;
  background: white;
  border: solid 2px $md-grey;
  cursor: pointer;
  display: inline-block;
  text-align: center;
  transition: background .3s;

  &:hover {
    background: lighten($md-grey, 30%);
  }
}

.btn {
  padding: 6px 12px;
  display: inline-block;
  background: $primary-color;
  color: white;
  cursor: pointer;
  border-radius: 3px;

  &:hover {
    color: white;
    background: lighten($primary-color, 10%);
  }
}

input {
  background: white;
  display: block;
  margin-bottom: 12px;
  width: 100%;
  box-sizing: border-box;
  border-bottom: solid 2px $md-grey-300;
  border-right: solid 1px $md-grey-100;
  text-align: left;

  &:focus {
    border-bottom-color: $primary-color;
  }
}

label input {
  display: inline-block;
  width: auto;
}

.form {
  margin-bottom: 12px;
}

.tooltip {
  display: block !important;
  z-index: 10000;

  .tooltip-inner {
    background: black;
    color: white;
    border-radius: 16px;
    padding: 5px 10px 4px;
  }

  .tooltip-arrow {
    width: 0;
    height: 0;
    border-style: solid;
    position: absolute;
    margin: 5px;
    border-color: black;
  }

  &[x-placement^="top"] {
    margin-bottom: 5px;

    .tooltip-arrow {
      border-width: 5px 5px 0 5px;
      border-left-color: transparent !important;
      border-right-color: transparent !important;
      border-bottom-color: transparent !important;
      bottom: -5px;
      left: calc(50% - 5px);
      margin-top: 0;
      margin-bottom: 0;
    }
  }

  &[x-placement^="bottom"] {
    margin-top: 5px;

    .tooltip-arrow {
      border-width: 0 5px 5px 5px;
      border-left-color: transparent !important;
      border-right-color: transparent !important;
      border-top-color: transparent !important;
      top: -5px;
      left: calc(50% - 5px);
      margin-top: 0;
      margin-bottom: 0;
    }
  }

  &[x-placement^="right"] {
    margin-left: 5px;

    .tooltip-arrow {
      border-width: 5px 5px 5px 0;
      border-left-color: transparent !important;
      border-top-color: transparent !important;
      border-bottom-color: transparent !important;
      left: -5px;
      top: calc(50% - 5px);
      margin-left: 0;
      margin-right: 0;
    }
  }

  &[x-placement^="left"] {
    margin-right: 5px;

    .tooltip-arrow {
      border-width: 5px 0 5px 5px;
      border-top-color: transparent !important;
      border-right-color: transparent !important;
      border-bottom-color: transparent !important;
      right: -5px;
      top: calc(50% - 5px);
      margin-left: 0;
      margin-right: 0;
    }
  }

  &[aria-hidden='true'] {
    visibility: hidden;
    opacity: 0;
    &:not(.no-transition) {
      transition: opacity .5s, visibility .5s;
    }
  }

  &[aria-hidden='false'] {
    visibility: visible;
    opacity: 1;
    &:not(.no-transition) {
      transition: opacity .5s;
    }
  }

  &.info {
    $color: rgba(#004499, .9);

    .tooltip-inner {
      background: $color;
      color: white;
      padding: 24px;
      border-radius: 5px;
      box-shadow: 0 5px 30px rgba(black, .1);
      max-width: 250px;
    }

    .tooltip-arrow {
      border-color: $color;
    }
  }

  &.popover {
    $color: #f9f9f9;

    .popover-inner {
      background: $color;
      color: black;
      padding: 24px;
      border-radius: 5px;
      box-shadow: 0 5px 30px rgba(black, .1);
    }

    .popover-arrow {
      border-color: $color;
    }
  }

  &.tooltip-loading {
    .tooltip-inner {
      color: #77aaff;
    }
  }
}

.v-popover {
  &.inline {
    display: inline-block;
    &:not(:last-child) {
      margin-right: 12px;
    }
  }
}

.command {
  background: darken($primary-color, 10%);
  color: white;
  font-family: monospace;
  max-width: 500px;
  margin: 12px auto;
  border-radius: 2px;
  padding: 12px 24px;
  box-sizing: border-box;
}

.snippet {
  margin: 16px 0;
}

.plus {
  text-align: center;
  color: $primary-color;
  font-size: 32px;
  margin: 12px;
}

.demo,
.snippets {
  margin: 0 42px;
}

.snippets {
  background: #f9f9f9;
  margin-bottom: 42px;
  border-radius: 0 0 3px 3px;
}

.demo {
  background: #eee;
  margin-top: 42px;
  border-radius: 3px 3px 0 0;

  .section-content {
    text-align: center;
    max-width: 560px;
    margin: auto;
  }

  h2 {
    margin-bottom: 24px;
  }

  button {
    width: 100px;
    height: 100px;
    border-radius: 50%;
    padding: 0;
    text-transform: uppercase;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    font-weight: bold;
    font-size: 16px;
    transform: rotate(-20deg);

    &.b2 {
      transform: rotate(30deg);
    }

    &.b3 {
      transform: rotate(-5deg);
    }

    &.popover-btn {
      background: #333;
      color: #eee;
      border-color: #999;
    }
  }
}

.more {
  font-size: 24px;
  text-align: center;
  background: lighten($primary-color, 45%);
}

</style>
