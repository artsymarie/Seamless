// Renders the slides in signs.html to ready-to-upload files:
//   signs/<slide>/artsy-<slide>-<shape>.png           spritesheet (24-bit, no alpha), 8 frames, no blanks
//   signs/<slide>/artsy-<slide>-<shape>.lsl           player script
//   signs/<slide>/artsy-<slide>-<shape>-preview.gif   half-size preview with the real timing
//   signs/extras/                                     ticker strip and spinning badge
//
// Same renderer as the studio, so the files match what signs.html shows on this machine,
// including its fonts. Avenir LT Pro is used only if it is installed here.
//
// Needs Node 18+ and Playwright:  npm i -D playwright && npx playwright install chromium
// Run from the repo root:          node tools/render-signs.js [square] [landscape] [portrait] [--out=dir]
'use strict';
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const root = path.resolve(__dirname, '..');
const args = process.argv.slice(2);
const outArg = args.find(a => a.startsWith('--out='));
const out = outArg ? path.resolve(outArg.slice(6)) : path.join(root, 'signs');
const shapes = args.filter(a => !a.startsWith('--')).length ? args.filter(a => !a.startsWith('--')) : ['square'];

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const problems = [];
  page.on('pageerror', e => problems.push('page error: ' + e.message));
  await page.goto('file://' + path.join(root, 'signs.html'));
  const poppins = await page.evaluate(() => window.SignStudio.ready);
  if (!poppins) {
    console.error('Poppins did not load from Google Fonts. Check the network and run again.');
    process.exit(1);
  }
  const fonts = await page.evaluate(() => window.SignStudio.fonts());
  console.log(`Body font: ${fonts.avenir === 'stand-in' ? 'Nunito Sans (Avenir LT Pro is not installed here)' : 'Avenir (' + fonts.avenir + ')'}`);
  const slides = await page.evaluate(() => window.SignStudio.slides);
  let failed = 0;
  for (const id of slides) {
    const dir = path.join(out, id);
    fs.mkdirSync(dir, { recursive: true });
    for (const shape of shapes) {
      const r = await page.evaluate(([id, shape]) => window.SignStudio.build(id, shape, 0.5), [id, shape]);
      r.sheets.forEach(s => fs.writeFileSync(path.join(dir, s.name + '.png'), Buffer.from(s.png, 'base64')));
      fs.writeFileSync(path.join(dir, r.base + '-preview.gif'), Buffer.from(r.gif, 'base64'));
      fs.writeFileSync(path.join(dir, r.base + '.lsl'), r.lsl);
      const bad = r.checks.filter(c => !c.ok);
      failed += bad.length;
      console.log(`${bad.length ? 'FAIL' : 'ok  '} ${r.base}  ${r.loop.toFixed(2)} s loop  ${r.runs} runs`);
      bad.forEach(c => console.log('       ! ' + c.text));
    }
  }
  const ex = await page.evaluate(() => window.SignStudio.extras());
  const exDir = path.join(out, 'extras');
  fs.mkdirSync(exDir, { recursive: true });
  fs.writeFileSync(path.join(exDir, 'artsy-ticker-2048x256.png'), Buffer.from(ex.ticker.png, 'base64'));
  fs.writeFileSync(path.join(exDir, 'artsy-ticker.lsl'), ex.ticker.lsl);
  fs.writeFileSync(path.join(exDir, 'artsy-badge-512.png'), Buffer.from(ex.badge.png, 'base64'));
  fs.writeFileSync(path.join(exDir, 'artsy-badge.lsl'), ex.badge.lsl);
  console.log('ok   extras: ticker 2048x256, badge 512x512');
  await browser.close();
  if (problems.length) { console.error(problems.join('\n')); process.exit(1); }
  if (failed) { console.error(`${failed} check(s) failed`); process.exit(1); }
})();
