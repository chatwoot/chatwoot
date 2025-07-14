'use strict';Object.defineProperty(exports, "__esModule", { value: true });exports['default'] =










childContext;var _hash = require('eslint-module-utils/hash');var parserOptionsHash = '';var prevParserOptions = '';var settingsHash = '';var prevSettings = ''; /**
                                                                                                                                                                 * don't hold full context object in memory, just grab what we need.
                                                                                                                                                                 * also calculate a cacheKey, where parts of the cacheKey hash are memoized
                                                                                                                                                                 */function childContext(path, context) {var settings = context.settings,parserOptions = context.parserOptions,parserPath = context.parserPath;if (JSON.stringify(settings) !== prevSettings) {
    settingsHash = (0, _hash.hashObject)({ settings: settings }).digest('hex');
    prevSettings = JSON.stringify(settings);
  }

  if (JSON.stringify(parserOptions) !== prevParserOptions) {
    parserOptionsHash = (0, _hash.hashObject)({ parserOptions: parserOptions }).digest('hex');
    prevParserOptions = JSON.stringify(parserOptions);
  }

  return {
    cacheKey: String(parserPath) + parserOptionsHash + settingsHash + String(path),
    settings: settings,
    parserOptions: parserOptions,
    parserPath: parserPath,
    path: path };

}
//# sourceMappingURL=data:application/json;charset=utf-8;base64,eyJ2ZXJzaW9uIjozLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy9leHBvcnRNYXAvY2hpbGRDb250ZXh0LmpzIl0sIm5hbWVzIjpbImNoaWxkQ29udGV4dCIsInBhcnNlck9wdGlvbnNIYXNoIiwicHJldlBhcnNlck9wdGlvbnMiLCJzZXR0aW5nc0hhc2giLCJwcmV2U2V0dGluZ3MiLCJwYXRoIiwiY29udGV4dCIsInNldHRpbmdzIiwicGFyc2VyT3B0aW9ucyIsInBhcnNlclBhdGgiLCJKU09OIiwic3RyaW5naWZ5IiwiZGlnZXN0IiwiY2FjaGVLZXkiLCJTdHJpbmciXSwibWFwcGluZ3MiOiI7Ozs7Ozs7Ozs7O0FBV3dCQSxZLENBWHhCLGdEQUVBLElBQUlDLG9CQUFvQixFQUF4QixDQUNBLElBQUlDLG9CQUFvQixFQUF4QixDQUNBLElBQUlDLGVBQWUsRUFBbkIsQ0FDQSxJQUFJQyxlQUFlLEVBQW5CLEMsQ0FFQTs7O21LQUllLFNBQVNKLFlBQVQsQ0FBc0JLLElBQXRCLEVBQTRCQyxPQUE1QixFQUFxQyxLQUMxQ0MsUUFEMEMsR0FDRkQsT0FERSxDQUMxQ0MsUUFEMEMsQ0FDaENDLGFBRGdDLEdBQ0ZGLE9BREUsQ0FDaENFLGFBRGdDLENBQ2pCQyxVQURpQixHQUNGSCxPQURFLENBQ2pCRyxVQURpQixDQUdsRCxJQUFJQyxLQUFLQyxTQUFMLENBQWVKLFFBQWYsTUFBNkJILFlBQWpDLEVBQStDO0FBQzdDRCxtQkFBZSxzQkFBVyxFQUFFSSxrQkFBRixFQUFYLEVBQXlCSyxNQUF6QixDQUFnQyxLQUFoQyxDQUFmO0FBQ0FSLG1CQUFlTSxLQUFLQyxTQUFMLENBQWVKLFFBQWYsQ0FBZjtBQUNEOztBQUVELE1BQUlHLEtBQUtDLFNBQUwsQ0FBZUgsYUFBZixNQUFrQ04saUJBQXRDLEVBQXlEO0FBQ3ZERCx3QkFBb0Isc0JBQVcsRUFBRU8sNEJBQUYsRUFBWCxFQUE4QkksTUFBOUIsQ0FBcUMsS0FBckMsQ0FBcEI7QUFDQVYsd0JBQW9CUSxLQUFLQyxTQUFMLENBQWVILGFBQWYsQ0FBcEI7QUFDRDs7QUFFRCxTQUFPO0FBQ0xLLGNBQVVDLE9BQU9MLFVBQVAsSUFBcUJSLGlCQUFyQixHQUF5Q0UsWUFBekMsR0FBd0RXLE9BQU9ULElBQVAsQ0FEN0Q7QUFFTEUsc0JBRks7QUFHTEMsZ0NBSEs7QUFJTEMsMEJBSks7QUFLTEosY0FMSyxFQUFQOztBQU9EIiwiZmlsZSI6ImNoaWxkQ29udGV4dC5qcyIsInNvdXJjZXNDb250ZW50IjpbImltcG9ydCB7IGhhc2hPYmplY3QgfSBmcm9tICdlc2xpbnQtbW9kdWxlLXV0aWxzL2hhc2gnO1xuXG5sZXQgcGFyc2VyT3B0aW9uc0hhc2ggPSAnJztcbmxldCBwcmV2UGFyc2VyT3B0aW9ucyA9ICcnO1xubGV0IHNldHRpbmdzSGFzaCA9ICcnO1xubGV0IHByZXZTZXR0aW5ncyA9ICcnO1xuXG4vKipcbiAqIGRvbid0IGhvbGQgZnVsbCBjb250ZXh0IG9iamVjdCBpbiBtZW1vcnksIGp1c3QgZ3JhYiB3aGF0IHdlIG5lZWQuXG4gKiBhbHNvIGNhbGN1bGF0ZSBhIGNhY2hlS2V5LCB3aGVyZSBwYXJ0cyBvZiB0aGUgY2FjaGVLZXkgaGFzaCBhcmUgbWVtb2l6ZWRcbiAqL1xuZXhwb3J0IGRlZmF1bHQgZnVuY3Rpb24gY2hpbGRDb250ZXh0KHBhdGgsIGNvbnRleHQpIHtcbiAgY29uc3QgeyBzZXR0aW5ncywgcGFyc2VyT3B0aW9ucywgcGFyc2VyUGF0aCB9ID0gY29udGV4dDtcblxuICBpZiAoSlNPTi5zdHJpbmdpZnkoc2V0dGluZ3MpICE9PSBwcmV2U2V0dGluZ3MpIHtcbiAgICBzZXR0aW5nc0hhc2ggPSBoYXNoT2JqZWN0KHsgc2V0dGluZ3MgfSkuZGlnZXN0KCdoZXgnKTtcbiAgICBwcmV2U2V0dGluZ3MgPSBKU09OLnN0cmluZ2lmeShzZXR0aW5ncyk7XG4gIH1cblxuICBpZiAoSlNPTi5zdHJpbmdpZnkocGFyc2VyT3B0aW9ucykgIT09IHByZXZQYXJzZXJPcHRpb25zKSB7XG4gICAgcGFyc2VyT3B0aW9uc0hhc2ggPSBoYXNoT2JqZWN0KHsgcGFyc2VyT3B0aW9ucyB9KS5kaWdlc3QoJ2hleCcpO1xuICAgIHByZXZQYXJzZXJPcHRpb25zID0gSlNPTi5zdHJpbmdpZnkocGFyc2VyT3B0aW9ucyk7XG4gIH1cblxuICByZXR1cm4ge1xuICAgIGNhY2hlS2V5OiBTdHJpbmcocGFyc2VyUGF0aCkgKyBwYXJzZXJPcHRpb25zSGFzaCArIHNldHRpbmdzSGFzaCArIFN0cmluZyhwYXRoKSxcbiAgICBzZXR0aW5ncyxcbiAgICBwYXJzZXJPcHRpb25zLFxuICAgIHBhcnNlclBhdGgsXG4gICAgcGF0aCxcbiAgfTtcbn1cbiJdfQ==