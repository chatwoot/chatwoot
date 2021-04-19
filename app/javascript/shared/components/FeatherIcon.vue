<template>
  <component :is="`icon-${name}`" :size="size"></component>
</template>

<script>
import { icons } from 'feather-icons';

const components = Object.values(icons).reduce(
  (prev, curr) => ({
    ...prev,
    [`icon-${curr.name}`]: {
      props: ['size'],
      render(createElement) {
        return createElement('div', {
          style: { display: 'inline-block' },
          domProps: {
            innerHTML: curr.toSvg({ width: this.size, height: this.size }),
          },
        });
      },
    },
  }),
  {}
);

export default {
  components,
  props: {
    name: {
      type: String,
      validator: value => {
        // eslint-disable-next-line no-prototype-builtins
        return icons.hasOwnProperty(value);
      },
      default: '',
    },
    size: {
      type: Number,
      default: 16,
    },
  },
};
</script>
