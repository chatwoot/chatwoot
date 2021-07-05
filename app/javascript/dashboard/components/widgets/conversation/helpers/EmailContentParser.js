export const stripStyleCharacters = emailContent => {
  let contentToBeParsed = emailContent.replace(/<style(.|\s)*?<\/style>/g, '');
  contentToBeParsed = contentToBeParsed.replace(/style="(.*?)"/g, '');
  let parsedContent = new DOMParser().parseFromString(
    contentToBeParsed,
    'text/html'
  );
  if (!parsedContent.getElementsByTagName('parsererror').length) {
    return parsedContent.body.innerHTML;
  }
  return '';
};
