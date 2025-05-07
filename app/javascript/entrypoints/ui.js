import { h, defineCustomElement } from 'vue';

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
