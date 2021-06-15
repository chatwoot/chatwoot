import ContactFields from '../components/ContactFields';
import { action } from '@storybook/addon-actions';

export default {
  title: 'Components/Contact/ContactFields',
  component: ContactFields,
};

const Template = (args, { argTypes }) => ({
  props: Object.keys(argTypes),
  components: { ContactFields },
  template:
    '<contact-fields v-bind="$props" :contact="contact" @update="onUpdate" @create-attribute="onCreate" />',
});

export const DefaultContactFields = Template.bind({});
DefaultContactFields.args = {
  contact: {
    id: 979442,
    name: 'Eden Hazard',
    title: 'Playmaker',
    thumbnail: 'https://randomuser.me/api/portraits/men/19.jpg',
    company: {
      id: 10,
      name: 'Chelsea',
    },
    email: 'hazard@chelsea.com',
    availability_status: 'offline',
    phone_number: '',
    custom_attributes: {},
    additional_attributes: {
      description:
        'Known for his dribbling, he is considered to be one of the best players in the world.',
      social_profiles: {
        twitter: 'hazardeden10',
        facebook: 'hazardeden10',
        linkedin: 'hazardeden10',
      },
    },
  },
  onUpdate: action('update'),
  onCreate: action('create'),
};
