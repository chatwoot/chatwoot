// Preset configurations for the Custom Tool form.
//
// These let a user scaffold a well-known integration (e.g. Cal.com or a
// generic order lookup) without hand-writing endpoint URLs, Liquid templates
// and param schemas. Each preset value matches the shape submitted by
// CustomToolForm. The user still provides their own credentials when needed.

const CAL_EVENT_TYPE_PLACEHOLDER = 'REPLACE_WITH_YOUR_EVENT_TYPE_ID';

export const CUSTOM_TOOL_PRESETS = [
  {
    id: 'order_lookup',
    label: 'Order Lookup',
    values: {
      title: 'Order Lookup',
      description: 'Looks up order details by order ID',
      http_method: 'GET',
      endpoint_url: 'https://api.example.com/orders/{{ order_id }}',
      auth_type: 'none',
      auth_config: {},
      additional_headers: {},
      request_template: '',
      response_template: 'Order {{ order_id }} status: {{ status }}',
      param_schema: [
        {
          name: 'order_id',
          type: 'string',
          description: 'The order ID to look up',
          required: true,
        },
      ],
    },
  },
  {
    id: 'cal_com_slots',
    label: 'Cal.com — Check availability',
    values: {
      title: 'Cal.com: Check availability',
      description:
        'Lists available booking slots for your Cal.com event type. Always call this first and only offer times it returns.',
      http_method: 'GET',
      endpoint_url: `https://api.cal.com/v2/slots?eventTypeId=${CAL_EVENT_TYPE_PLACEHOLDER}&start={{start}}&end={{end}}&timeZone={{time_zone}}&format=range`,
      auth_type: 'bearer',
      auth_config: { token: '' },
      additional_headers: { 'cal-api-version': '2024-08-13' },
      request_template: '',
      response_template: '',
      param_schema: [
        {
          name: 'start',
          type: 'string',
          description:
            'Start date of the availability window (e.g. 2026-09-01). Today if the customer wants the soonest slot.',
          required: true,
        },
        {
          name: 'end',
          type: 'string',
          description: 'End date of the availability window (e.g. 2026-09-07).',
          required: true,
        },
        {
          name: 'time_zone',
          type: 'string',
          description:
            "Customer's IANA time zone (e.g. Asia/Jakarta). Used to return local slot times.",
          required: true,
        },
      ],
    },
  },
  {
    id: 'cal_com_booking',
    label: 'Cal.com — Book appointment',
    values: {
      title: 'Cal.com: Book appointment',
      description:
        "Create a Cal.com booking. Book ONLY a slot returned by the availability tool, and confirm the customer's preferred time first.",
      http_method: 'POST',
      endpoint_url: 'https://api.cal.com/v2/bookings',
      auth_type: 'bearer',
      auth_config: { token: '' },
      additional_headers: { 'cal-api-version': '2026-02-25' },
      request_template: `{
  "eventTypeId": ${CAL_EVENT_TYPE_PLACEHOLDER},
  "start": "{{ start_time }}",
  "attendee": {
    "name": "{{ attendee_name }}",
    "email": "{{ attendee_email }}",
    "timeZone": "{{ time_zone }}"
  }
}`,
      response_template:
        'Booking created (reference: {{ r.data.uid }}). Start: {{ r.data.start }}. End: {{ r.data.end }}. Status: {{ r.data.status }}.',
      param_schema: [
        {
          name: 'attendee_name',
          type: 'string',
          description: "Customer's full name (prefer the contact name).",
          required: true,
        },
        {
          name: 'attendee_email',
          type: 'string',
          description: "Customer's email (prefer the contact email).",
          required: true,
        },
        {
          name: 'time_zone',
          type: 'string',
          description:
            "Customer's IANA time zone (e.g. Asia/Jakarta). Must match the slot query time zone.",
          required: true,
        },
        {
          name: 'start_time',
          type: 'string',
          description:
            'Start time as a full ISO 8601 timestamp taken from the chosen slot (e.g. 2026-08-18T15:00:00Z).',
          required: true,
        },
      ],
    },
  },
];
