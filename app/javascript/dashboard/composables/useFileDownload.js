import { downloadFile } from '@chatwoot/utils';

/**
 * Downloads an attachment, falling back to opening it when the download cannot be built.
 *
 * `downloadFile` fetches the file to turn it into a blob. Attachment URLs are Active Storage
 * redirects, so with a cloud storage service the fetch follows a 302 to another origin and is
 * refused unless that bucket sends CORS headers for the dashboard origin. Playback and previews
 * keep working because `<audio>`, `<video>` and `<img>` are exempt from CORS, which makes the
 * failed download button look like it does nothing. When the fetch fails, hand the URL to the
 * browser instead, which follows the redirect the same way the file chips' plain links do.
 */
export const useFileDownload = () => {
  const download = async ({ url, type, extension }) => {
    try {
      await downloadFile({ url, type, extension });
    } catch (error) {
      window.open(url, '_blank', 'noopener');
    }
  };

  return { download };
};
