# Build Vite assets (app) and SDK before Rails assets precompile so AssetSync can upload them
namespace :vite do
  desc "Build Vite assets"
  task :build do
    sh "bin/vite build"
  end

  desc "Build Vite SDK in library mode to public/packs/js/sdk.js"
  task :build_sdk do
    sh({ 'BUILD_MODE' => 'library' }, "bin/vite build")
  end
end

# Ensure both builds happen before asset upload/sync
task 'assets:precompile' => ['vite:build', 'vite:build_sdk']
