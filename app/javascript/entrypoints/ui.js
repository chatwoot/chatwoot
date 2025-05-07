import { h, defineCustomElement } from 'vue';

// Import dashboard styles
import '../dashboard/assets/scss/app.scss';
import 'vue-multiselect/dist/vue-multiselect.css';
// Import floating-vue styles from dashboard.js
import 'floating-vue/dist/style.css';

const ChatButton = {
  name: 'ChatButton',
  props: {
    label: {
      type: String,
      default: 'Click me',
    },
  },
  render() {
    return h(
      'button',
      {
        class: 'cha-button',
        onClick: this.handleClick,
      },
      this.label
    );
  },
  methods: {
    handleClick() {
      // console.log('Button clicked');
    },
  },
};

export const buttonElement = defineCustomElement(ChatButton);
