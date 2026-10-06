// Renders every kinetic sign in signs.html to ready-to-upload files:
//   signs/<sign>/artsy-<sign>-<format>-<cols>x<rows>.png   spritesheet (24-bit, no alpha)
//   signs/<sign>/artsy-<sign>-<format>-<cols>x<rows>.gif   preview with the real timing
//   signs/<sign>/artsy-<sign>-<format>-<cols>x<rows>.lsl   player script
//   signs/extras/                                          ticker strip and spinning badge
//
// It uses the same renderer as the studio, so the files match what signs.html shows.
// Needs Node 18+ and Playwright:  npm i -D playwright && npx playwright install chromium
// Run from the repo root:          node tools/render-signs.js
'use strict';
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const root = path.resolve(__dirname, '..');
const out = path.join(root, 'signs');
const page_url = 'file://' + path.join(root, 'signs.html');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  const problems = [];
  page.on('pageerror', e => problems.push('page error: ' + e.message));
  await page.goto(page_url);
  const fontsOk = await page.evaluate(() => window.SignStudio.ready);
  if (!fontsOk) {
    console.error('The web fonts did not load (Archivo, Instrument Serif, Space Mono). Check the network and run again.');
    process.exit(1);
  }
  const { signs, formats } = await page.evaluate(() => ({ signs: window.SignStudio.signs, formats: window.SignStudio.formats }));
  let failed = 0;
  for (const id of signs) {
    const dir = path.join(out, id);
    fs.mkdirSync(dir, { recursive: true });
    for (const fmt of formats) {
      const r = await page.evaluate(([id, fmt]) => window.SignStudio.build(id, fmt), [id, fmt]);
      fs.writeFileSync(path.join(dir, r.name + '.png'), Buffer.from(r.png, 'base64'));
      fs.writeFileSync(path.join(dir, r.name + '.gif'), Buffer.from(r.gif, 'base64'));
      fs.writeFileSync(path.join(dir, r.name + '.lsl'), r.lsl);
      const bad = r.checks.filter(c => !c.ok);
      failed += bad.length;
      const loop = r.holds.reduce((a, b) => a + b, 0).toFixed(2);
      console.log(`${bad.length ? 'FAIL' : 'ok  '} ${r.name}  ${r.sheet.join('x')}  ${r.grid.join('x')} grid  ${r.cell.join('x')} cells  ${loop}s loop  ${r.runs} runs`);
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
