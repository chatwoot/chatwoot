<template>
  <div role="application" aria-label="PhotoShop color picker" :class="['vc-photoshop', disableFields ? 'vc-photoshop__disable-fields' : '']">
    <div role="heading" class="vc-ps-head">{{head}}</div>
    <div class="vc-ps-body">
      <div class="vc-ps-saturation-wrap">
        <saturation v-model="colors" @change="childChange"></saturation>
      </div>
      <div class="vc-ps-hue-wrap">
        <hue v-model="colors" @change="childChange" direction="vertical">
          <div class="vc-ps-hue-pointer">
            <i class="vc-ps-hue-pointer--left"></i><i class="vc-ps-hue-pointer--right"></i>
          </div>
        </hue>
      </div>
      <div :class="['vc-ps-controls', disableFields ? 'vc-ps-controls__disable-fields' : '']">
        <div class="vc-ps-previews">
          <div class="vc-ps-previews__label">{{ newLabel }}</div>
          <div class="vc-ps-previews__swatches">
            <div class="vc-ps-previews__pr-color" :aria-label="`New color is ${colors.hex}`" :style="{background: colors.hex}"></div>
            <div class="vc-ps-previews__pr-color" :aria-label="`Current color is ${currentColor}`" :style="{background: currentColor}" @click="clickCurrentColor"></div>
          </div>
          <div class="vc-ps-previews__label">{{ currentLabel }}</div>
        </div>
        <div class="vc-ps-actions" v-if="!disableFields">
          <div class="vc-ps-ac-btn" role="button" :aria-label="acceptLabel" @click="handleAccept">{{ acceptLabel }}</div>
          <div class="vc-ps-ac-btn" role="button" :aria-label="cancelLabel" @click="handleCancel">{{ cancelLabel }}</div>

          <div class="vc-ps-fields">
            <!-- hsla -->
            <ed-in label="h" desc="°" :value="hsv.h" @change="inputChange"></ed-in>
            <ed-in label="s" desc="%" :value="hsv.s" :max="100" @change="inputChange"></ed-in>
            <ed-in label="v" desc="%" :value="hsv.v" :max="100" @change="inputChange"></ed-in>
            <div class="vc-ps-fields__divider"></div>
            <!-- rgba -->
            <ed-in label="r" :value="colors.rgba.r" @change="inputChange"></ed-in>
            <ed-in label="g" :value="colors.rgba.g" @change="inputChange"></ed-in>
            <ed-in label="b" :value="colors.rgba.b" @change="inputChange"></ed-in>
            <div class="vc-ps-fields__divider"></div>
            <!-- hex -->
            <ed-in label="#" class="vc-ps-fields__hex" :value="hex" @change="inputChange"></ed-in>
          </div>

          <div v-if="hasResetButton" class="vc-ps-ac-btn" aria-label="reset" @click="handleReset">{{ resetLabel }}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import colorMixin from '../mixin/color'
import editableInput from './common/EditableInput.vue'
import saturation from './common/Saturation.vue'
import hue from './common/Hue.vue'
import alpha from './common/Alpha.vue'

export default {
  name: 'Photoshop',
  mixins: [colorMixin],
  props: {
    head: {
      type: String,
      default: 'Color Picker'
    },
    disableFields: {
      type: Boolean,
      default: false
    },
    hasResetButton: {
      type: Boolean,
      default: false
    },
    acceptLabel: {
      type: String,
      default: 'OK'
    },
    cancelLabel: {
      type: String,
      default: 'Cancel'
    },
    resetLabel: {
      type: String,
      default: 'Reset'
    },
    newLabel: {
      type: String,
      default: 'new'
    },
    currentLabel: {
      type: String,
      default: 'current'
    }
  },
  components: {
    saturation,
    hue,
    alpha,
    'ed-in': editableInput
  },
  data () {
    return {
      currentColor: '#FFF'
    }
  },
  computed: {
    hsv () {
      const hsv = this.colors.hsv
      return {
        h: hsv.h.toFixed(),
        s: (hsv.s * 100).toFixed(),
        v: (hsv.v * 100).toFixed()
      }
    },
    hex () {
      const hex = this.colors.hex
      return hex && hex.replace('#', '')
    }
  },
  created () {
    this.currentColor = this.colors.hex
  },
  methods: {
    childChange (data) {
      this.colorChange(data)
    },
    inputChange (data) {
      if (!data) {
        return
      }
      if (data['#']) {
        this.isValidHex(data['#']) && this.colorChange({
          hex: data['#'],
          source: 'hex'
        })
      } else if (data.r || data.g || data.b || data.a) {
        this.colorChange({
          r: data.r || this.colors.rgba.r,
          g: data.g || this.colors.rgba.g,
          b: data.b || this.colors.rgba.b,
          a: data.a || this.colors.rgba.a,
          source: 'rgba'
        })
      } else if (data.h || data.s || data.v) {
        this.colorChange({
          h: data.h || this.colors.hsv.h,
          s: (data.s / 100) || this.colors.hsv.s,
          v: (data.v / 100) || this.colors.hsv.v,
          source: 'hsv'
        })
      }
    },
    clickCurrentColor () {
      this.colorChange({
        hex: this.currentColor,
        source: 'hex'
      })
    },
    handleAccept () {
      this.$emit('ok')
    },
    handleCancel () {
      this.$emit('cancel')
    },
    handleReset () {
      this.$emit('reset')
    }
  }

}
</script>

<style>
.vc-photoshop {
  background: #DCDCDC;
  border-radius: 4px;
  box-shadow: 0 0 0 1px rgba(0,0,0,.25), 0 8px 16px rgba(0,0,0,.15);
  box-sizing: initial;
  width: 513px;
  font-family: Roboto;
}
.vc-photoshop__disable-fields {
  width: 390px;
}
.vc-ps-head {
  background-image: linear-gradient(-180deg, #F0F0F0 0%, #D4D4D4 100%);
  border-bottom: 1px solid #B1B1B1;
  box-shadow: inset 0 1px 0 0 rgba(255,255,255,.2), inset 0 -1px 0 0 rgba(0,0,0,.02);
  height: 23px;
  line-height: 24px;
  border-radius: 4px 4px 0 0;
  font-size: 13px;
  color: #4D4D4D;
  text-align: center;
}
.vc-ps-body {
  padding: 15px;
  display: flex;
}

.vc-ps-saturation-wrap {
  width: 256px;
  height: 256px;
  position: relative;
  border: 2px solid #B3B3B3;
  border-bottom: 2px solid #F0F0F0;
  overflow: hidden;
}
.vc-ps-saturation-wrap .vc-saturation-circle {
  width: 12px;
  height: 12px;
}

.vc-ps-hue-wrap {
  position: relative;
  height: 256px;
  width: 19px;
  margin-left: 10px;
  border: 2px solid #B3B3B3;
  border-bottom: 2px solid #F0F0F0;
}
.vc-ps-hue-pointer {
  position: relative;
}
.vc-ps-hue-pointer--left,
.vc-ps-hue-pointer--right {
  position: absolute;
  width: 0;
  height: 0;
  border-style: solid;
  border-width: 5px 0 5px 8px;
  border-color: transparent transparent transparent #555;
}
.vc-ps-hue-pointer--left:after,
.vc-ps-hue-pointer--right:after {
  content: "";
  width: 0;
  height: 0;
  border-style: solid;
  border-width: 4px 0 4px 6px;
  border-color: transparent transparent transparent #fff;
  position: absolute;
  top: 1px;
  left: 1px;
  transform: translate(-8px, -5px);
}
.vc-ps-hue-pointer--left {
  transform: translate(-13px, -4px);
}
.vc-ps-hue-pointer--right {
  transform: translate(20px, -4px) rotate(180deg);
}

.vc-ps-controls {
  width: 180px;
  margin-left: 10px;
  display: flex;
}
.vc-ps-controls__disable-fields {
  width: auto;
}

.vc-ps-actions {
  margin-left: 20px;
  flex: 1;
}
.vc-ps-ac-btn {
  cursor: pointer;
  background-image: linear-gradient(-180deg, #FFFFFF 0%, #E6E6E6 100%);
  border: 1px solid #878787;
  border-radius: 2px;
  height: 20px;
  box-shadow: 0 1px 0 0 #EAEAEA;
  font-size: 14px;
  color: #000;
  line-height: 20px;
  text-align: center;
  margin-bottom: 10px;
}
.vc-ps-previews {
  width: 60px;
}
.vc-ps-previews__swatches {
  border: 1px solid #B3B3B3;
  border-bottom: 1px solid #F0F0F0;
  margin-bottom: 2px;
  margin-top: 1px;
}
.vc-ps-previews__pr-color {
  height: 34px;
  box-shadow: inset 1px 0 0 #000, inset -1px 0 0 #000, inset 0 1px 0 #000;
}
.vc-ps-previews__label {
  font-size: 14px;
  color: #000;
  text-align: center;
}

.vc-ps-fields {
  padding-top: 5px;
  padding-bottom: 9px;
  width: 80px;
  position: relative;
}
.vc-ps-fields .vc-input__input {
  margin-left: 40%;
  width: 40%;
  height: 18px;
  border: 1px solid #888888;
  box-shadow: inset 0 1px 1px rgba(0,0,0,.1), 0 1px 0 0 #ECECEC;
  margin-bottom: 5px;
  font-size: 13px;
  padding-left: 3px;
  margin-right: 10px;
}
.vc-ps-fields .vc-input__label, .vc-ps-fields .vc-input__desc {
  top: 0;
  text-transform: uppercase;
  font-size: 13px;
  height: 18px;
  line-height: 22px;
  position: absolute;
}
.vc-ps-fields .vc-input__label {
  left: 0;
  width: 34px;
}
.vc-ps-fields .vc-input__desc {
  right: 0;
  width: 0;
}

.vc-ps-fields__divider {
  height: 5px;
}

.vc-ps-fields__hex .vc-input__input {
  margin-left: 20%;
  width: 80%;
  height: 18px;
  border: 1px solid #888888;
  box-shadow: inset 0 1px 1px rgba(0,0,0,.1), 0 1px 0 0 #ECECEC;
  margin-bottom: 6px;
  font-size: 13px;
  padding-left: 3px;
}
.vc-ps-fields__hex .vc-input__label {
  position: absolute;
  top: 0;
  left: 0;
  width: 14px;
  text-transform: uppercase;
  font-size: 13px;
  height: 18px;
  line-height: 22px;
}
</style>
