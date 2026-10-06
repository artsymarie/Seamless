# Seamless Separator

A single-file browser tool that turns found seamless pattern tiles, including messy ones (photos, scans, JPEG-damaged downloads, uneven lighting, tinted paper), into clean production tiles:

- **Black & white**: solid two-color tile, or anti-aliased, in pure black/white or the source ink/paper colors.
- **Color ID**: every separate shape gets a unique flat color. Palettes: distinct hues, random RGB, or index-encoded (R + G·256 + B·65536 = ID) for pipelines. Background can be white, black, transparent, or given its own IDs.
- **SVG**: traced outlines (sharp or smooth curves) that repeat cleanly.

Everything runs on a torus: blur, thresholding, speck removal, shape labeling and tracing all wrap around the tile edges. The outputs stay seamless, and a shape cut by the tile edge keeps a single ID.

## Use

Open `index.html` in a browser. There's nothing to install or build.

1. Drop, choose, or paste (Ctrl/⌘+V) one or more tiles.
2. Check the **seam** pills. They show whether the source actually wraps left–right and top–bottom.
3. Ink and paper colors are auto-detected with two-means color clustering. For colored or low-contrast sources, click **Ink** or **Paper** and click the pattern to sample it.
4. Start from a preset (**Organic / brush**, **Geometric**, **Rough photo / scan**) and adjust:
   - **Detail**: processes at 2× or 4× for smoother edges and larger output (capped at 3200 px working size).
   - **Even out lighting**: local ink/paper normalization for shadows, vignetting and folds.
   - **Edge smoothing**: wraparound Gaussian before thresholding. Lower it for crisp geometric corners.
   - **Line weight**: shifts the auto (Otsu) threshold thinner or heavier.
   - **Remove specks / Fill pinholes**: drops islands and holes below an area in source px².
5. Switch views with the toolbar or keys `1`–`4`. Use **Repeat** to inspect the tiling, and drag or scroll to pan and zoom.
6. Export B&W PNG, Color ID PNG, SVG, or a ZIP of all loaded tiles.

## Limits

- The tool cleans a tile. It doesn't *make* a non-repeating image seamless. If the seam check says the source has a visible seam, the output will too.
- Two-tone separation only for now: one ink against one paper.

# Sign Studio

`signs.html` makes kinetic black-and-white display signs for the Second Life store. The six signs are redelivery, freebies, tint, reflection probes, purchase info and welcome. Each comes in portrait, landscape and square and exports as an even spritesheet: power-of-two size, every cell used, 8 frames at 512 px per metre. A GIF preview and an LSL player script that handles the hold times come with each sheet. There's also a smooth ticker strip and a spinning badge that use no frames at all.

Open `signs.html` in a browser to change the copy and timing and export. The ready-made sheets, previews, scripts and setup steps are in [`signs/`](signs/README.md).
