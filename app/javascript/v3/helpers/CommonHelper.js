export const replaceRouteWithReload = url => {
  window.location = url;
};

export const userInitial = name => {
  const parts = name.split(/[ -]/).filter(Boolean);
  let initials = parts.map(part => part[0].toUpperCase()).join('');
  return initials.slice(0, 2);
};
