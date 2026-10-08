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

`signs.html` makes looping slides for the Second Life store, one per message: redelivery, collections, delivery, permissions, textures, tint, shine, reflection probes, tutorials, welcome, freebies and patterns. They share the look of the artsy record sleeves: matte black and bone, a thin inset rule, wide-tracked capitals and the script logo. Each slide comes in black, bone, or two-tone like the split sleeve. The whole message is on screen in every frame, so nothing ever goes blank. Each slide moves between two states and back, or runs a short move once a loop. It is set in Poppins and Avenir LT Pro, using your own copy of Avenir.

Every slide is 8 frames on one sheet with every cell used: 2048 × 1024 for square, 2048 × 2048 for landscape and portrait, all at 512 px per metre. An LSL player times the holds and plays the way back in reverse, so no frame is ever repeated. There's also a smooth ticker strip and a spinning record badge that use no frames at all.

Open `signs.html` in a browser to change the copy and timing and export. Ready-made square slides, previews, scripts and setup steps are in [`signs/`](signs/README.md).
