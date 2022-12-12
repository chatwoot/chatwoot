<template>
  <div id="app">
    <a class="github-fork-ribbon" href="https://github.com/xiaokaike/vue-color" title="Fork me on GitHub">Fork me on GitHub</a>
    <div class="header-container">
      <div class="header-bg" :style="{'background-color': bgc}"></div>
      <div class="header">
        <div class="intro-wrap">
          <div class="intro">
            <h1>Vue-color</h1>
            <p role="presentation">A Collection of Color Pickers from Sketch, Photoshop, Chrome, Github, Twitter, Material Design & more</p>
          </div>
        </div>
        <div class="demo-item">
          <chrome-picker :value="colors" @input="updateValue"></chrome-picker>
          <h2>Chrome</h2>
        </div>
      </div>
    </div>

    <div class="demo-container">
      <div class="demo-list">
        <div class="demo-item">
          <sketch-picker v-model="colors"></sketch-picker>
          <h2>Sketch</h2>
        </div>
        <div class="demo-item">
          <photoshop-picker v-model="colors" @ok="onOk" @cancel="onCancel"></photoshop-picker>
          <h2>Photoshop</h2>
        </div>
      </div>
      <div class="demo-list">
        <div class="demo-item">
          <material-picker v-model="colors"></material-picker>
          <h2>Material</h2>
        </div>
        <div class="demo-item">
          <slider-picker v-model="colors"></slider-picker>
          <h2>Slider</h2>
        </div>
      </div>
      <div class="demo-list">
        <div class="demo-item">
          <compact-picker v-model="colors"></compact-picker>
          <h2>Compact</h2>
          <br>
          <br>
          <grayscale-picker :value="colors" @input="updateValue"></grayscale-picker>
          <h2>Grayscale</h2>
        </div>
        <div class="demo-item">
          <swatches-picker v-model="colors"></swatches-picker>
          <h2>Swatches</h2>
        </div>
      </div>
      <div class="demo-list">
        <div class="demo-item">
          <twitter-picker :value="colors" @input="updateValue"></twitter-picker>
          <h2>Twitter</h2>
        </div>
      </div>

    </div>
  </div>
</template>

<script>
import material from '../src/components/Material.vue'
import compact from '../src/components/Compact.vue'
import grayscale from '../src/components/Grayscale.vue'
import swatches from '../src/components/Swatches.vue'
import slider from '../src/components/Slider.vue'
import sketch from '../src/components/Sketch.vue'
import chrome from '../src/components/Chrome.vue'
import photoshop from '../src/components/Photoshop.vue'
import twitter from '../src/components/Twitter.vue'

let defaultProps = {
  hex: '#194d33e6',
  hsl: {
    h: 150,
    s: 0.5,
    l: 0.2,
    a: 0.9
  },
  hsv: {
    h: 150,
    s: 0.66,
    v: 0.30,
    a: 0.9
  },
  rgba: {
    r: 159,
    g: 96,
    b: 43,
    a: 0.9
  },
  a: 0.9
}

export default {
  components: {
    'material-picker': material,
    'compact-picker': compact,
    'grayscale-picker': grayscale,
    'swatches-picker': swatches,
    'slider-picker': slider,
    'sketch-picker': sketch,
    'chrome-picker': chrome,
    'photoshop-picker': photoshop,
    'twitter-picker': twitter
  },
  data () {
    return {
      colors: defaultProps
    }
  },
  computed: {
    bgc () {
      return this.colors.hex
    }
  },
  methods: {
    onOk () {
      console.log('ok')
    },
    onCancel () {
      console.log('cancel')
    },
    updateValue (value) {
      this.colors = value
    }
  },
  created () {
  }
}
</script>

<style>
* {
  margin: 0;
  padding: 0;
}
html {
  font-family: 'Source Sans Pro', 'Helvetica Neue', Arial, sans-serif;
}

.header-container {
  position: relative;
}
.header-bg {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  min-height: 580px;
  background-color: #333;
  opacity: 0.5;
  z-index: 0;
}
.header {
  display: flex;
  max-width: 780px;
  margin: 0 auto;
  padding: 20px 0;
}
.intro-wrap {
  flex: 1;
  margin-right: 100px;
}
.intro {
  width: 300px;
  color: rgba(0, 0, 0, 0.65098);
}
.intro > h1 {
  font-size: 40px;
  font-weight: normal;
  line-height: 60px;
}
.intro > p {
  font-size: 16px;
  font-weight: normal;
  line-height: 22px;
}

.demo-container {
  max-width: 780px;
  min-height: 800px;
  margin: 0 auto;
  position: relative;
  z-index: 2;
}
.demo-list {
  display: flex;
  margin-bottom: 20px;
}
.demo-item {
  position: relative;
  margin-bottom: 10px;
  margin: 0 10px 0 10px;
  z-index: 2;
}
.demo-item h2 {
  margin: 0;
  padding: 5px 0;
  color: #666;
  font-size: 16px;
  font-weight: normal;
}
</style>
