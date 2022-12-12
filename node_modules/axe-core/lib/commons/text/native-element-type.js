const nativeElementType = [
  {
    // 5.1 input type="text", input type="password", input type="search", input type="tel", input type="url" and textarea Element
    matches: [
      {
        nodeName: 'textarea'
      },
      {
        nodeName: 'input',
        properties: {
          type: ['text', 'password', 'search', 'tel', 'email', 'url']
        }
      }
    ],
    namingMethods: 'labelText'
  },
  {
    // 5.2 input type="button", input type="submit" and input type="reset"
    matches: {
      nodeName: 'input',
      properties: {
        type: ['button', 'submit', 'reset']
      }
    },
    namingMethods: ['valueText', 'titleText', 'buttonDefaultText']
  },
  {
    // 5.3 input type="image"
    matches: {
      nodeName: 'input',
      properties: {
        type: 'image'
      }
    },
    namingMethods: [
      'altText',
      'valueText',
      'labelText',
      'titleText',
      'buttonDefaultText'
    ]
  },
  {
    // 5.4 button Element
    matches: 'button',
    namingMethods: 'subtreeText'
  },
  {
    // 5.5 fieldset and legend Elements
    matches: 'fieldset',
    namingMethods: 'fieldsetLegendText'
  },
  {
    // 5.6 output Element
    matches: 'OUTPUT',
    namingMethods: 'subtreeText'
  },
  {
    // 5.7 Other Form Elements
    matches: [
      {
        nodeName: 'select'
      },
      {
        nodeName: 'input',
        properties: {
          // Regex: Everything other than these
          type: /^(?!text|password|search|tel|email|url|button|submit|reset)/
        }
      }
    ],
    namingMethods: 'labelText'
  },
  {
    // 5.8 summary Element
    matches: 'summary',
    namingMethods: 'subtreeText'
  },
  {
    // 5.9 figure and figcaption Elements
    matches: 'figure',
    namingMethods: ['figureText', 'titleText']
  },
  {
    // 5.10 img Element
    matches: 'img',
    namingMethods: 'altText'
  },
  {
    // 5.11 table Element
    matches: 'table',
    namingMethods: ['tableCaptionText', 'tableSummaryText']
  },
  {
    matches: ['hr', 'br'],
    namingMethods: ['titleText', 'singleSpace']
  }
  // All else defaults to just title
];

export default nativeElementType;
