const { execSync } = require('child_process');
const fs = require('fs');

console.log('🔗 Publishing Chatwoot React Components via Yalc...');

function yalcPublish() {
  try {
    // Check if yalc is installed
    try {
      execSync('yalc --version', { stdio: 'pipe' });
    } catch (error) {
      console.error('❌ Yalc is not installed globally.');
      console.log('💡 Install yalc: npm install -g yalc');
      process.exit(1);
    }

    // Check if package exists
    const packageDir = 'dist/react-components';
    if (!fs.existsSync(packageDir)) {
      console.log('📦 Package not found. Building first...');
      execSync('node scripts/publish-react-components.js', {
        stdio: 'inherit',
      });
    }

    // Publish with yalc
    console.log('🚀 Publishing to yalc store...');
    execSync('yalc publish', {
      cwd: packageDir,
      stdio: 'inherit',
    });

    console.log('');
    console.log('✅ Published to yalc store!');
    console.log('');
    console.log('📖 Next steps in your test project:');
    console.log('  1. yalc add @chatwoot/react-components');
    console.log('  2. npm install');
    console.log('  3. Import and use the components');
    console.log('');
    console.log('🔄 To update after changes:');
    console.log('  1. pnpm package:react:yalc-publish  (in this repo)');
    console.log('  2. yalc update                      (in test project)');
  } catch (error) {
    console.error('❌ Yalc publish failed:', error.message);
    process.exit(1);
  }
}

yalcPublish();
