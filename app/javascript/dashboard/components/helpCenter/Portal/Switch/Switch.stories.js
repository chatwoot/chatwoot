import PortalSwitch from './Index.vue';

export default {
  title: 'Components/Help Center/Portal Switch',
  component: PortalSwitch,
  argTypes: {
    active: {
      defaultValue: false,
      control: {
        type: 'boolean',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { PortalSwitch },
  template:
    '<PortalSwitch v-bind="$props" @click="onClick">{{label}}</PortalSwitch>',
});

export const Primary = Template.bind({});
