<template>
  <div role="application" aria-label="Grayscale color picker" class="vc-grayscale">
    <ul class="vc-grayscale-colors" role="listbox">
      <li
        v-for="c in paletteUpperCase(palette)"
        role="option"
        :aria-label="'Color:' + c"
        :aria-selected="c === pick"
        :key="c"
        class="vc-grayscale-color-item"
        :class="{'vc-grayscale-color-item--white': c == '#FFFFFF'}"
        :style="{background: c}"
        @click="handlerClick(c)"
      >
        <div class="vc-grayscale-dot" v-show="c === pick"></div>
      </li>
    </ul>
  </div>
</template>

<script>
import colorMixin from '../mixin/color'

const defaultColors = [
  '#FFFFFF', '#F2F2F2', '#E6E6E6', '#D9D9D9', '#CCCCCC', '#BFBFBF', '#B3B3B3',
  '#A6A6A6', '#999999', '#8C8C8C', '#808080', '#737373', '#666666', '#595959',
  '#4D4D4D', '#404040', '#333333', '#262626', '#0D0D0D', '#000000'
]

export default {
  name: 'Grayscale',
  mixins: [colorMixin],
  props: {
    palette: {
      type: Array,
      default () {
        return defaultColors
      }
    }
  },
  components: {

  },
  computed: {
    pick () {
      return this.colors.hex.toUpperCase()
    }
  },
  methods: {
    handlerClick (c) {
      this.colorChange({
        hex: c,
        source: 'hex'
      })
    }
  }
}

</script>

<style>
.vc-grayscale {
  width: 125px;
  border-radius: 2px;
  box-shadow: 0 2px 15px rgba(0,0,0,.12), 0 2px 10px rgba(0,0,0,.16);
  background-color: #fff;
}
.vc-grayscale-colors {
  border-radius: 2px;
  overflow: hidden;
  padding: 0;
  margin: 0;
}
.vc-grayscale-color-item {
  list-style: none;
  width: 25px;
  height: 25px;
  float: left;
  position: relative;
  cursor: pointer;
}
.vc-grayscale-color-item--white .vc-grayscale-dot {
  background: #000;
}

.vc-grayscale-dot {
  position: absolute;
  top: 50%;
  left: 50%;
  width: 6px;
  height: 6px;
  margin: -3px 0 0 -2px;
  border-radius: 50%;
  opacity: 1;
  background: #fff;
}
</style>
