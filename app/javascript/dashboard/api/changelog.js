import ApiClient from './ApiClient';

class ChangelogApi extends ApiClient {
  constructor() {
    super('changelog', { apiVersion: 'v1' });
  }

  // eslint-disable-next-line class-methods-use-this
  fetchFromHub() {
    // Return hardcoded data for now - will be replaced with API URL later
    const hardcodedData = {
      posts: [
        {
          url: 'https://www-internal-blog.chatwoot.com/whatsapp-account-health-and-allowed-domains/',
          slug: 'whatsapp-account-health-and-allowed-domains',
          title: 'WhatsApp Account Health and Allowed Domains',
          excerpt:
            'WhatsApp Account Health\n\nWe’ve added a new Account Health tab under WhatsApp Inbox settings. It shows your number’s current status, messaging limits, display name, and quality rating all in one place.\n\nThis helps teams quickly verify if their number is active, healthy, and ready to send messages without having to switch to Meta Business Manager. For deeper checks, there’s a direct link to open your WhatsApp Manager dashboard.\n\n\nWeb Widget: Allowed Domains\n\nYou can now restrict where your web wid',
          og_title: null,
          meta_title: 'WhatsApp Health',
          published_at: '2025-10-10T12:29:54.000+00:00',
          email_subject: null,
          feature_image: null,
          twitter_title: null,
          custom_excerpt: null,
          og_description: null,
          meta_description: 'Track your WhatsApp account metrics',
          twitter_description: null,
        },
        {
          url: 'https://www-internal-blog.chatwoot.com/mfa-and-pdf-support/',
          slug: 'mfa-and-pdf-support',
          title: 'Multi-Factor Authentication and Captain PDF Uploads',
          excerpt:
            'This release focuses on practical improvements that make everyday work smoother: stronger security, and better ways to manage knowledge in Captain. Alongside these, we’ve made a set of smaller updates and fixes that address feedback from teams using Chatwoot day to day.\n\n\nCaptain Now Supports PDF Documents\n\n\nYou can now upload PDFs as knowledge sources in Captain. This allows you to bring existing documents like product manuals, training guides, or policy documents into Captain without convertin',
          og_title: null,
          meta_title: 'MFA Login',
          published_at: '2025-09-19T12:13:10.000+00:00',
          email_subject: null,
          feature_image: null,
          twitter_title: null,
          custom_excerpt: null,
          og_description: null,
          meta_description: 'Add extra security to your account',
          twitter_description: null,
        },
        {
          url: 'https://www-internal-blog.chatwoot.com/twilio-content-templates/',
          slug: 'twilio-content-templates',
          title: 'Twilio Content Templates',
          excerpt:
            'This release brings one of the most requested features, along with a handful of quality-of-life improvements and a set of smaller fixes.\n\nIf you’re using Twilio’s WhatsApp Business API, you can send pre-approved WhatsApp templates directly from Chatwoot. These templates are required to start new WhatsApp conversations and are also useful for sending structured messages, like appointment reminders or verification codes, that comply with WhatsApp’s rules.\n\nPlease read more details about here.\n\n\nOt',
          og_title: null,
          meta_title: 'Twilio Templates',
          published_at: '2025-08-29T11:14:16.000+00:00',
          email_subject: null,
          feature_image: null,
          twitter_title: null,
          custom_excerpt: null,
          og_description: null,
          meta_description: 'Send pre-approved messages with Twilio',
          twitter_description: null,
        },
        {
          url: 'https://www-internal-blog.chatwoot.com/enhanced-whatsapp-templates-coexistence-and-small-fixes/',
          slug: 'enhanced-whatsapp-templates-coexistence-and-small-fixes',
          title: 'Enhanced WhatsApp Templates and Coexistence',
          excerpt:
            'This release brings better WhatsApp support and a set of small fixes across the app. Nothing big, just steady improvements to make daily use easier.\n\n\nEnhanced Embedded WhatsApp Coexistence\n\nWe’ve added support for the coexistence method in Embedded WhatsApp. This lets you connect an existing WhatsApp Business number to Chatwoot without losing its current setup.\n\nConversation history sync will come in a later release.\n\n\nEnhanced WhatsApp Template Support with Media Headers\n\nYou can now use media',
          og_title: null,
          meta_title: 'Coexistence',
          published_at: '2025-08-18T10:32:47.000+00:00',
          email_subject: null,
          feature_image: null,
          twitter_title: null,
          custom_excerpt: null,
          og_description: null,
          meta_description: 'Connect existing number in WhatsApp',
          twitter_description: null,
        },
        {
          url: 'https://www-internal-blog.chatwoot.com/easier-custom-domains-and-mobile-ui-improvements/',
          slug: 'easier-custom-domains-and-mobile-ui-improvements',
          title: 'Easier Custom Domains and Mobile UI Improvements',
          excerpt:
            "This update is focused on simplifying a few core workflows, mainly around custom domains and mobile experience. It's a smaller release, but a meaningful one if you're working with our Help Center or managing inboxes on the go.\n\n\n🌐 Custom Domain Setup Made Easier\n\nWe’ve improved the flow for setting up custom domains on your Help Center. You can now verify DNS and activate SSL certificates directly from the Chatwoot UI—no need to reach out to support or wait for manual intervention.\n\nOnce you up",
          og_title: null,
          meta_title: 'Custom Domains',
          published_at: '2025-08-04T14:03:29.000+00:00',
          email_subject: null,
          feature_image: null,
          twitter_title: null,
          custom_excerpt: null,
          og_description: null,
          meta_description: 'Simplify setup with guided configuration',
          twitter_description: null,
        },
      ],
      last_synced_at: '2025-10-15T08:19:01.226Z',
      synced_posts_count: 5,
    };

    return Promise.resolve({ data: hardcodedData });
  }
}

export default new ChangelogApi();
