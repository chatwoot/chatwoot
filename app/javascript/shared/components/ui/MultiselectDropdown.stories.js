import { action } from '@storybook/addon-actions';
import Dropdown from './MutiselectDropdown';

export default {
  title: 'Components/Dropdown/Multiselect Dropdown',
  component: Dropdown,
  argTypes: {
    options: {
      control: {
        type: 'object',
      },
    },
    value: {
      control: {
        type: 'object',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { Dropdown },
  template: '<dropdown v-bind="$props" @click="onClick"></dropdown>',
});

export const MultiselectDropdown = Template.bind({});
MultiselectDropdown.args = {
  onClick: action('Opened'),
  options: [
    {
      id: 1,
      availability_status: 'online',
      name: 'James Philip',
      thumbnail: 'https://randomuser.me/api/portraits/men/4.jpg',
    },
  ],

  value: {
    id: 1,
    availability_status: 'online',
    name: 'James Philip',
    thumbnail: 'https://randomuser.me/api/portraits/men/4.jpg',
  },
};
