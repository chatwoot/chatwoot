import { action } from '@storybook/addon-actions';
import SectionHeader from './SectionHeader';

export default {
  title: 'Components/Events/Section',
  component: SectionHeader,
  argTypes: {},
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { SectionHeader },
  template:
    '<section-header v-bind="$props" @notes="onClickNotes" @events="onClickEvents" @conversation="onClickConversation"></section-header>',
});

export const Section = Template.bind({});
Section.args = {
  onClickNotes: action('notes'),
  onClickEvents: action('events'),
  onClickConversation: action('conversation'),
};
