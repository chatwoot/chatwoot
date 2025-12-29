/**
 * Script para actualizar referencias de Chatwoot a Hablia en archivos de configuración
 * Ejecuta después de reemplazar los logos físicos
 */

const fs = require('fs');
const path = require('path');

const filesToUpdate = [
  {
    path: path.join(__dirname, '..', 'app.json'),
    updates: [
      {
        search: /"logo":\s*"https:\/\/app\.chatwoot\.com\/brand-assets\/logo_thumbnail\.svg"/,
        replace: '"logo": "https://tu-dominio-hablia.com/brand-assets/logo_thumbnail.svg"'
      },
      {
        search: /"name":\s*"Chatwoot"/,
        replace: '"name": "Hablia Care"'
      },
      {
        search: /"description":\s*"Chatwoot is a customer support tool for instant messaging channels"/,
        replace: '"description": "Hablia Care - Plataforma de atención al cliente"'
      },
      {
        search: /"website":\s*"https:\/\/www\.chatwoot\.com\/"/,
        replace: '"website": "https://tu-dominio-hablia.com/"'
      },
      {
        search: /"repository":\s*"https:\/\/github\.com\/chatwoot\/chatwoot"/,
        replace: '"repository": "https://github.com/tu-usuario/chatwoot-hablia"'
      }
    ]
  },
  {
    path: path.join(__dirname, '..', 'config', 'installation_config.yml'),
    updates: [
      {
        search: /value:\s*'Chatwoot'/g,
        replace: "value: 'Hablia Care'"
      },
      {
        search: /value:\s*'https:\/\/www\.chatwoot\.com'/g,
        replace: "value: 'https://tu-dominio-hablia.com'"
      }
    ]
  },
  {
    path: path.join(__dirname, '..', 'enterprise', 'config', 'premium_installation_config.yml'),
    updates: [
      {
        search: /value:\s*'Chatwoot'/g,
        replace: "value: 'Hablia Care'"
      },
      {
        search: /value:\s*'https:\/\/www\.chatwoot\.com'/g,
        replace: "value: 'https://tu-dominio-hablia.com'"
      }
    ]
  }
];

function updateFile(filePath, updates) {
  try {
    let content = fs.readFileSync(filePath, 'utf8');
    let modified = false;

    updates.forEach(update => {
      if (content.match(update.search)) {
        content = content.replace(update.search, update.replace);
        modified = true;
        console.log(`✓ Actualizado en ${path.basename(filePath)}`);
      }
    });

    if (modified) {
      fs.writeFileSync(filePath, content, 'utf8');
      return true;
    }
    return false;
  } catch (error) {
    console.error(`✗ Error actualizando ${filePath}:`, error.message);
    return false;
  }
}

function main() {
  console.log('📝 Actualizando referencias en archivos de configuración...\n');

  let totalUpdated = 0;
  filesToUpdate.forEach(file => {
    if (fs.existsSync(file.path)) {
      if (updateFile(file.path, file.updates)) {
        totalUpdated++;
      }
    } else {
      console.log(`⚠ Archivo no encontrado: ${file.path}`);
    }
  });

  if (totalUpdated > 0) {
    console.log(`\n✅ Actualizados ${totalUpdated} archivos`);
    console.log('\n⚠ NOTA: Por favor revisa y actualiza manualmente:');
    console.log('   - URLs de dominio en app.json');
    console.log('   - URLs de dominio en config/installation_config.yml');
    console.log('   - URLs de dominio en enterprise/config/premium_installation_config.yml');
  } else {
    console.log('\nℹ No se encontraron referencias para actualizar');
  }
}

main();

