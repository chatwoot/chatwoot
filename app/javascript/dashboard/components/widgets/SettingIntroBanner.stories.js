import SettingIntroBanner from './SettingIntroBanner';

export default {
  title: 'Components/Settings/Banner',
  component: SettingIntroBanner,
  argTypes: {
    headerTitle: {
      defaultValue: 'Acme Support',
      control: {
        type: 'text',
      },
    },
    headerContent: {
      defaultValue:
        'It is a long established fact that a reader will be distracted by the readable content of a page when looking at its layout.',
      control: {
        type: 'text',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { SettingIntroBanner },
  template: '<setting-intro-banner v-bind="$props" ></setting-intro-banner>',
});

export const Banner = Template.bind({});
Banner.args = {};
