import { action } from '@storybook/addon-actions';
import TimelineCard from './TimelineCard';

export default {
  title: 'Components/Events/Timeline',
  component: TimelineCard,
  argTypes: {
    eventType: {
      defaultValue: 'Commented',
      control: {
        type: 'text',
      },
    },
    eventPath: {
      defaultValue: 'chatwoot/chatwoot',
      control: {
        type: 'text',
      },
    },
    eventBody: {
      defaultValue:
        'Commentedmany variations of passages of Lorem Ipsum available, but the majority have suffered alteration in some form, by injected humour',
      control: {
        type: 'text',
      },
    },
    timeStamp: {
      defaultValue: '1618046084',
      control: {
        type: 'number',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { TimelineCard },
  template: '<timeline-card v-bind="$props" @more="onClick"></timeline-card>',
});

export const Timeline = Template.bind({});
Timeline.args = {
  onClick: action('more'),
};
