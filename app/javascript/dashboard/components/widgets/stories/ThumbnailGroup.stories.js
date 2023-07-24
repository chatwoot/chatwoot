import ThumbnailGroup from '../ThumbnailGroup.vue';

export default {
  title: 'Components/ThumbnailGroup',
  component: ThumbnailGroup,
  argTypes: {
    usersList: {
      defaultValue: [
        {
          name: 'John',
          id: 1,
          thumbnail: '',
        },
        {
          name: 'John',
          id: 2,
          thumbnail: '',
        },
        {
          name: 'John',
          id: 3,
          thumbnail: '',
        },
        {
          name: 'John',
          id: 4,
          thumbnail: '',
        },
        {
          name: 'John',
          id: 5,
          thumbnail: '',
        },
        {
          name: 'John',
          id: 6,
          thumbnail: '',
        },
      ],
      control: {
        type: 'object',
      },
    },
    size: {
      control: {
        type: 'text',
      },
    },
    moreThumbnailsText: {
      control: {
        type: 'text',
        default: '2 more',
      },
    },
    showMoreThumbnailsCount: {
      control: {
        type: 'boolean',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ThumbnailGroup },
  template: '<ThumbnailGroup v-bind="$props"/>',
});

export const Primary = Template.bind({});
