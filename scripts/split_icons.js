const { Jimp } = require('jimp');
const path = require('path');
const fs = require('fs');

const inputPath = process.argv[2] || 'assets/images/categories/Food.png';
const outputDir = 'assets/images/category_icons';
const rows = 6;
const cols = 4;

const labels = [
  'burger', 'mi', 'minuman', 'dessert',
  'nasi', 'roti', 'fast_food', 'pizza',
  'lauk_1', 'donat_1', 'snack_1', 'permen',
  'lauk_2', 'donat_2', 'snack_2', 'kue',
  'ayam_1', 'sup_1', 'buah', 'minuman_panas',
  'ayam_2', 'sup_2', 'sushi', 'steak_bakar'
];

async function splitGrid() {
  if (!fs.existsSync(inputPath)) {
    console.error(`Error: Input file not found at ${inputPath}`);
    process.exit(1);
  }

  const image = await Jimp.read(inputPath);
  const { width, height } = image.bitmap;
  
  const cellWidth = Math.floor(width / cols);
  const cellHeight = Math.floor(height / rows);

  console.log(`Image dimensions: ${width}x${height}`);
  console.log(`Cell dimensions: ${cellWidth}x${cellHeight}`);

  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  for (let r = 0; r < rows; r++) {
    for (let c = 0; c < cols; c++) {
      const index = r * cols + c;
      if (index >= labels.length) break;

      const label = labels[index];
      const x = c * cellWidth;
      const y = r * cellHeight;

      // Crop margins to avoid label text if possible, or just crop the icon box
      // Each cell in the grid has the icon at top and label at bottom.
      // We want to capture the whole cell or just the icon.
      // Usually, people want just the icon.
      // Based on the image, the icon is in a rounded box.
      
      const icon = image.clone().crop({ x, y, w: cellWidth, h: cellHeight });
      const outputPath = path.join(outputDir, `${label}.png`);
      await icon.write(outputPath);
      console.log(`Saved: ${outputPath}`);
    }
  }
}

splitGrid().catch(err => {
  console.error(err);
  process.exit(1);
});
