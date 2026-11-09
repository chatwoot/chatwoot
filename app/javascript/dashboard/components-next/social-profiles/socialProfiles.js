// hosts[0] builds the link; the rest are other hosts the network is known by.
export const SOCIAL_NETWORKS = {
  linkedin: { icon: 'i-ri-linkedin-box-fill', hosts: ['linkedin.com/'] },
  x: { icon: 'i-ri-twitter-x-fill', hosts: ['x.com/', 'twitter.com/'] },
  twitter: { icon: 'i-ri-twitter-x-fill', hosts: ['x.com/', 'twitter.com/'] },
  facebook: { icon: 'i-ri-facebook-circle-fill', hosts: ['facebook.com/'] },
  instagram: { icon: 'i-ri-instagram-fill', hosts: ['instagram.com/'] },
  github: { icon: 'i-ri-github-fill', hosts: ['github.com/'] },
  youtube: { icon: 'i-ri-youtube-fill', hosts: ['youtube.com/'] },
  tiktok: { icon: 'i-ri-tiktok-fill', hosts: ['tiktok.com/@'] },
  telegram: { icon: 'i-ri-telegram-fill', hosts: ['t.me/'] },
};

const PROTOCOL = /^https?:\/\/(www\.)?/i;

export const socialProfileUrl = (network, handle) => {
  const value = (handle || '').trim();
  if (!value || PROTOCOL.test(value)) return value;
  const config = SOCIAL_NETWORKS[network];
  return config ? `https://${config.hosts[0]}${value}` : '';
};

export const socialProfileHandle = (network, url) => {
  const value = (url || '').trim();
  const path = value.replace(PROTOCOL, '');
  const host = SOCIAL_NETWORKS[network].hosts.find(item =>
    path.toLowerCase().startsWith(item)
  );
  return host ? path.slice(host.length).replace(/\/$/, '') : value;
};
