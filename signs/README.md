# Glass slides

One looping slide per message for the store in Second Life, made with [`signs.html`](../signs.html). The whole message is on screen in every frame, so a slide is never blank. The motion comes from the slide itself: it slides between two states and back, or a light passes across the frosted glass.

| Preview | Slide | What moves | Loop |
|---|---|---|---|
| <img src="redelivery/artsy-redelivery-square-preview.gif" width="120" alt="Redelivery slide"> | Redelivery | The cursor clicks twice: loaded, then sent to your inventory | 9.8 s |
| <img src="collections/artsy-collections-square-preview.gif" width="120" alt="Collections slide"> | Collections | The arrow nudges toward the terminal | 4.0 s |
| <img src="delivery/artsy-delivery-square-preview.gif" width="120" alt="Delivery slide"> | Delivery | A material drops into the Materials folder | 7.0 s |
| <img src="permissions/artsy-permissions-square-preview.gif" width="120" alt="Permissions slide"> | Permissions | The selection moves from Copy / Mod to Full Perm | 9.6 s |
| <img src="textures/artsy-textures-square-preview.gif" width="120" alt="Textures slide"> | Textures | The texture maps fan out | 4.8 s |
| <img src="tint/artsy-tint-square-preview.gif" width="120" alt="Tint slide"> | Tint | The material ball darkens as the tint changes | 6.4 s |
| <img src="shine/artsy-shine-square-preview.gif" width="120" alt="Shine slide"> | Shine | The roughness and metallic sliders move, and the highlight sharpens | 8.6 s |
| <img src="probes/artsy-probes-square-preview.gif" width="120" alt="Reflection probes slide"> | Reflection probes | The probe box scales up and the ball starts reflecting the room | 9.8 s |
| <img src="tutorials/artsy-tutorials-square-preview.gif" width="120" alt="Tutorials slide"> | Tutorials | The play button pulses | 3.8 s |
| <img src="welcome/artsy-welcome-square-preview.gif" width="120" alt="Welcome slide"> | Welcome | Light runs across the logo | 4.8 s |
| <img src="freebies/artsy-freebies-square-preview.gif" width="120" alt="Freebies slide"> | Freebies | The swatches lift one after another | 5.8 s |
| <img src="patterns/artsy-patterns-square-preview.gif" width="120" alt="Patterns slide"> | Patterns | Light passes over each pattern | 4.8 s |

The previews are half size. Upload the PNG sheets, not the GIFs. The repo has the square set; the studio exports landscape and portrait.

## Fonts

Headings and labels are Poppins. Body text is Avenir LT Pro, which is a licensed font, so it is never bundled here. The files in this folder were rendered on a machine without it, so their body text uses Nunito Sans, the closest free match.

For the real thing, open `signs.html` on a computer that has Avenir LT Pro installed (a Mac's built-in Avenir also works), or click **Add Avenir LT Pro files** and pick your font files. They stay in the browser and are not uploaded. Then use **All slides in this shape (.zip)** to export the whole set.

## Sheets

Every slide is 8 frames, and every frame is the finished slide. There are no blank, empty or half-built frames anywhere, and every cell of the sheet is used.

| Shape | Frame | Grid | Sheet | Prim face |
|---|---|---|---|---|
| Square 1:1 | 512 × 512 | 4 × 2 | 2048 × 1024 | 1 × 1 m |
| Landscape 2:1 | 1024 × 512 | 2 × 4 | 2048 × 2048 | 2 × 1 m |
| Portrait 1:2 | 512 × 1024 | 4 × 2 | 2048 × 2048 | 1 × 2 m |

All three come out at 512 pixels per metre at those sizes. Any size with the same ratio works. Frames are read left to right, top to bottom, which is how `llSetTextureAnim` counts them.

The 8 frames follow one of two plans:

| Slide | Frame 0 | Frames 1 to 6 or 7 | Loop |
|---|---|---|---|
| Two states (Redelivery, Delivery, Permissions, Tint, Shine, Reflection probes) | First state | The move to the second state; frame 7 is the second state | Forwards, hold, backwards, hold |
| One message (the rest) | The message | A light passing across the glass, with the illustration's own move | The light passes, then the message holds |

The way back is the move played in reverse, and every hold is timed by the script, so neither costs a frame.

## Setting one up in Second Life

1. Upload the PNG.
2. Rez a box, flatten it, and size the display face to the slide's ratio (1:1, 2:1 or 1:2).
3. Apply the texture to that face. Full Bright on, Glow 0, Alpha mode None.
4. Drop the matching `.lsl` script into the prim.

The script animates `ALL_SIDES`. If the box's other faces have their own textures or materials, set `FACE` at the top of the script to the display face number.

### Timing

The script's `TIMELINE` lists each frame and its seconds on screen. Edit it in-world to change how long the message or each state stays up; no new upload needed. The studio has the same settings, and its exports carry your timing.

Each move plays inside a single `llSetTextureAnim` call, forwards or with `REVERSE`, so the viewer times it precisely. The script's timer only starts each run, twice per loop, and a run without `LOOP` stays on its last frame. Lag can stretch a hold, but it never shows a wrong frame.

## Zero-frame motion

Two extras in [`extras/`](extras/) move without any frames. The viewer animates a single texture, so the motion is smooth at full frame rate.

- **Ticker strip** (`artsy-ticker-2048x256.png`): text that scrolls forever and repeats seamlessly at the texture edge. `WINDOWS` in the script sets how much shows at once: 1 for an 8:1 strip (4 × 0.5 m), 2 for 4:1 (2 × 0.5 m), 4 for a 2:1 panel. Set `FLIP` if it runs the wrong way on your prim.
- **Spinning badge** (`artsy-badge-512.png`): ring text with transparent corners. Alpha mode: Alpha masking, cutoff 128. Repeats 1 × 1, no offset or rotation on the face.

## Changing copy

Open [`signs.html`](../signs.html) in Chrome or Edge. Pick a slide and a shape, change the copy and timing, then export the sheet, the GIF, the script, or a zip of everything. **All slides in this shape** exports the whole set in one zip. Edits are saved in that browser.

To re-render the files in this folder from the studio's defaults:

```sh
npm i -D playwright && npx playwright install chromium
node tools/render-signs.js                       # square
node tools/render-signs.js landscape portrait    # the other shapes as well
```

The script stops with an error if a sheet breaks the rules above: not a power of two within 2048, an uneven grid, a blank or repeated cell, or too many flashes.
