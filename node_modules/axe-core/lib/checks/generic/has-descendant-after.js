function pageHasElmAfter(results) {
  const elmUsedAnywhere = results.some(
    frameResult => frameResult.result === true
  );

  // If the element exists in any frame, set them all to true
  if (elmUsedAnywhere) {
    results.forEach(result => {
      result.result = true;
    });
  }
  return results;
}

export default pageHasElmAfter;
