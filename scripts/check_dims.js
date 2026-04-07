const { Jimp } = require('jimp');
const fs = require('fs');
const path = require('path');

async function checkAll(dir) {
  const files = fs.readdirSync(dir, { recursive: true });
  for (const f of files) {
    const full = path.join(dir, f);
    if (f.endsWith('.png') || f.endsWith('.jpg') || f.endsWith('.jpeg') || f.endsWith('.webp')) {
      try {
        const img = await Jimp.read(full);
        console.log(`${full}: ${img.bitmap.width}x${img.bitmap.height}`);
      } catch (e) {}
    }
  }
}

checkAll('assets/images').catch(err => console.error(err));
