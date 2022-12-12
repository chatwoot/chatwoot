function pageNoDuplicateAfter(results) {
  // ignore results
  return results.filter(checkResult => checkResult.data !== 'ignored');
}

export default pageNoDuplicateAfter;
