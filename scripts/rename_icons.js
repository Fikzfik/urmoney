const fs = require('fs');
const path = require('path');

const baseDir = path.join(__dirname, '..', 'assets', 'images', 'category_icons');

const mapping = {
  'row-1-column-1.png': 'burger.png',
  'row-1-column-2.png': 'mi.png',
  'row-1-column-3.png': 'minuman.png',
  'row-1-column-4.png': 'dessert.png',
  'row-2-column-1.png': 'nasi.png',
  'row-2-column-2.png': 'roti.png',
  'row-2-column-3.png': 'fast_food.png',
  'row-2-column-4.png': 'pizza.png',
  'row-3-column-1.png': 'lauk_1.png',
  'row-3-column-2.png': 'donat_1.png',
  'row-3-column-3.png': 'snack_1.png',
  'row-3-column-4.png': 'permen.png',
  'row-4-column-1.png': 'lauk_2.png',
  'row-4-column-2.png': 'donat_2.png',
  'row-4-column-3.png': 'snack_2.png',
  'row-4-column-4.png': 'kue.png',
  'row-5-column-1.png': 'ayam_1.png',
  'row-5-column-2.png': 'sup_1.png',
  'row-5-column-3.png': 'buah.png',
  'row-5-column-4.png': 'minuman_panas.png',
  'row-6-column-1.png': 'ayam_2.png',
  'row-6-column-2.png': 'sup_2.png',
  'row-6-column-3.png': 'sushi.png',
  'row-6-column-4.png': 'steak_bakar.png',
};

Object.entries(mapping).forEach(([oldName, newName]) => {
  const oldPath = path.join(baseDir, oldName);
  const newPath = path.join(baseDir, newName);
  if (fs.existsSync(oldPath)) {
    console.log(`Renaming ${oldName} to ${newName}`);
    fs.renameSync(oldPath, newPath);
  } else {
    console.log(`Warning: ${oldName} not found`);
  }
});
