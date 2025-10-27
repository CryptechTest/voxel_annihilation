const fs = require('fs');
const path = require('path');

function cleanGltfFile(filePath) {
  let data = fs.readFileSync(filePath, 'utf8');
  let gltf;
  try {
    gltf = JSON.parse(data);
  } catch (e) {
    console.error(`Failed to parse ${filePath}:`, e);
    return;
  }

  // Remove textures, images, samplers
  delete gltf.textures;
  delete gltf.images;
  delete gltf.samplers;

  // Clean materials
  if (Array.isArray(gltf.materials)) {
    gltf.materials.forEach(mat => {
      if (mat.pbrMetallicRoughness) {
        delete mat.pbrMetallicRoughness.baseColorTexture;
        if (!mat.pbrMetallicRoughness.baseColorFactor) {
          mat.pbrMetallicRoughness.baseColorFactor = [0.8, 0.8, 0.8, 1];
        }
      }
    });
  }

  fs.writeFileSync(filePath, JSON.stringify(gltf, null, 2), 'utf8');
  console.log(`Cleaned: ${filePath}`);
}

function findGltfFiles(dir) {
  fs.readdirSync(dir, { withFileTypes: true }).forEach(entry => {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      findGltfFiles(fullPath);
    } else if (entry.isFile() && entry.name.endsWith('.gltf')) {
      cleanGltfFile(fullPath);
    }
  });
}

// Start from current directory
findGltfFiles(process.cwd());