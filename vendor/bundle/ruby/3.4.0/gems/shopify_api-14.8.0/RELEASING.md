# Releasing ShopifyAPI

1. Before releasing, make sure `sorbet` and related gems are up to date:
   `bundle update sorbet sorbet-runtime sorbet-static tapioca --conservative`
1. Check the Semantic Versioning page for info on how to version the new release: http://semver.org
1. Update the version of ShopifyAPI in lib/shopify_api/version.rb
1. Run `bundle`
1. Add a CHANGELOG entry for the new release
1. Commit the changes with a commit message like "Packaging for release X.Y.Z"
1. Tag the release with the version (Leave REV blank for HEAD or provide a SHA)
   $ git tag vX.Y.Z REV
1. Push out the changes
   $ git push
1. Push out the tags
   $ git push --tags
1. Publish the gem using Shipit
1. Consider if the dependency in Shopify/shopify needs updated. It's used only by the tests so is a low risk change.
   Also consider Shopify/shopify_app whose gemspec depends on this.
   We don't need to do this for every release, but we should try to keep them relatively up to date.
