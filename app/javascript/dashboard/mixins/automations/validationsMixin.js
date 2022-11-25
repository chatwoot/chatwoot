import { required, requiredIf } from 'vuelidate/lib/validators';

export default {
  validations: {
    automation: {
      name: {
        required,
      },
      description: {
        required,
      },
      event_name: {
        required,
      },
      conditions: {
        required,
        $each: {
          values: {
            required: requiredIf(prop => {
              return !(
                prop.filter_operator === 'is_present' ||
                prop.filter_operator === 'is_not_present'
              );
            }),
          },
        },
      },
      actions: {
        required,
        $each: {
          action_params: {
            required: requiredIf(prop => {
              return !(
                prop.action_name === 'mute_conversation' ||
                prop.action_name === 'snooze_conversation' ||
                prop.action_name === 'resolve_conversation'
              );
            }),
          },
        },
      },
    },
  },
};
