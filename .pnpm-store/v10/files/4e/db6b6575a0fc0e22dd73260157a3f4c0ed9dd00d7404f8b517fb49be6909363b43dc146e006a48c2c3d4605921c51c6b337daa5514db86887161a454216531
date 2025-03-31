export const stringToArrayBuffer = (string) => {
  const view = new Uint8Array(new ArrayBuffer(string.length));

  for (let i = 0; i < string.length; i++) {
    view[i] = string.charCodeAt(i);
  }

  return view.buffer;
};
