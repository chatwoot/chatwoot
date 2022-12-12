function uniqueFrameTitleAfter(results) {
  var titles = {};
  results.forEach(r => {
    titles[r.data] = titles[r.data] !== undefined ? ++titles[r.data] : 0;
  });
  results.forEach(r => {
    r.result = !!titles[r.data];
  });

  return results;
}

export default uniqueFrameTitleAfter;
