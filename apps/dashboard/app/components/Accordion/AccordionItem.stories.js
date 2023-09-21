import { action } from '@storybook/addon-actions';
import AccordionItemComponent from './AccordionItem';

export default {
  title: 'Components/Generic/Accordion',
  component: AccordionItemComponent,
  argTypes: {
    title: {
      control: {
        type: 'string',
      },
    },
  },
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { AccordionItem: AccordionItemComponent },
  template: `
    <accordion-item v-bind="$props" @click="onClick">
    This is a sample content you can pass as a slot
    </accordion-item>
  `,
});

export const AccordionItem = Template.bind({});
AccordionItem.args = {
  onClick: action('Added'),
  title: 'Title of the accordion item',
};
