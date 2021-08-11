import { action } from '@storybook/addon-actions';
import Dropdown from './MultiselectDropdown';

export default {
  title: 'Components/Dropdown/Multiselect Dropdown',
  component: Dropdown,
  argTypes: {
    options: {
      control: {
        type: 'object',
      },
    },
    selectedItem: {
      control: {
        type: 'object',
      },
    },
    multiselectorTitle: {
      control: {
        type: 'text',
      },
    },
    multiselectorPlaceholder: {
      control: {
        type: 'text',
      },
    },
    noSearchResult: {
      control: {
        type: 'text',
      },
    },
    inputPlaceholder: {
      control: {
        type: 'text',
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

  selectedItem: {
    id: 1,
    availability_status: 'online',
    name: 'James Philip',
    thumbnail: 'https://randomuser.me/api/portraits/men/4.jpg',
  },
};
