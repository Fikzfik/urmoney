const fs = require('fs');
const path = require('path');

const srcDir = path.join(__dirname, '..', 'assets', 'images', 'category_icons');
const destDir = path.join(__dirname, '..', 'assets', 'images', 'categories', 'makanan');

if (!fs.existsSync(destDir)) {
    fs.mkdirSync(destDir, { recursive: true });
}

const targets = [];
for (let i = 1; i <= 24; i++) {
    targets.push(`food_${i}.png`);
}

const files = fs.readdirSync(srcDir).filter(f => f.endsWith('.png') && !f.includes('Kawaii'));

console.log(`Found ${files.length} icons in ${srcDir}`);

files.forEach((f, i) => {
    if (i < 24) {
        const src = path.join(srcDir, f);
        const dest = path.join(destDir, targets[i]);
        fs.copyFileSync(src, dest);
        console.log(`Copied ${f} to ${targets[i]}`);
    }
});

// Fill remaining if less than 24
if (files.length > 0 && files.length < 24) {
    for (let i = files.length; i < 24; i++) {
        const src = path.join(srcDir, files[files.length - 1]);
        const dest = path.join(destDir, targets[i]);
        fs.copyFileSync(src, dest);
        console.log(`Duplicated ${files[files.length - 1]} to ${targets[i]}`);
    }
}

console.log('Reorganization complete.');
