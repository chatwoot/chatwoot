/* eslint no-unused-vars: ["error", { "args": "none" }] */
/* eslint prefer-template: 0 */
/* eslint no-console: 0 */
/* eslint func-names: 0 */
import TWEEN from 'tween.js';

export default {
  name: 'WootTabsItem',
  props: {
    index: {
      type: Number,
      default: 0,
    },
    name: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      default: false,
    },
    count: {
      type: Number,
      default: 0,
    },
  },

  data() {
    return {
      animatedNumber: 0,
    };
  },

  computed: {
    active() {
      return this.index === this.$parent.index;
    },

    getItemCount() {
      return this.animatedNumber || this.count;
    },
  },

  watch: {
    count(newValue, oldValue) {
      let animationFrame;
      const animate = time => {
        TWEEN.update(time);
        animationFrame = window.requestAnimationFrame(animate);
      };
      const that = this;
      new TWEEN.Tween({ tweeningNumber: oldValue })
        .easing(TWEEN.Easing.Quadratic.Out)
        .to({ tweeningNumber: newValue }, 500)
        .onUpdate(function() {
          that.animatedNumber = this.tweeningNumber.toFixed(0);
        })
        .onComplete(() => {
          window.cancelAnimationFrame(animationFrame);
        })
        .start();
      animationFrame = window.requestAnimationFrame(animate);
    },
  },

  render(h) {
    return (
      <li
        class={{
          'tabs-title': true,
          'is-active': this.active,
          'uk-disabled': this.disabled,
        }}
      >
        <a
          on-click={event => {
            event.preventDefault();
            if (!this.disabled) {
              this.$parent.$emit('change', this.index);
            }
          }}
        >
          {`${this.name}`}
          <span class="badge">{this.getItemCount}</span>
        </a>
      </li>
    );
  },
};
