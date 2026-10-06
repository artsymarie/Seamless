// artsy ticker: one texture, smooth scroll, no frames
// Texture: artsy-ticker-2048x256 (8:1). The text repeats seamlessly at the texture edge.
// Put it on the strip's display face: Full Bright on, Glow 0, Alpha mode None.

integer FACE    = ALL_SIDES;  // set your display face number if other faces have their own textures
integer WINDOWS = 2;        // how much of the texture shows at once:
                              // 1 = 8:1 strip (e.g. 4 x 0.5 m), 2 = 4:1 strip (2 x 0.5 m), 4 = 2:1 panel (1 x 0.5 m)
float   SECONDS = 24.00;    // time for the whole texture to pass once
integer FLIP    = FALSE;      // TRUE if it runs the wrong way on your prim

default
{
    state_entry()
    {
        integer mode = ANIM_ON | SMOOTH | LOOP;
        if (FLIP) mode = mode | REVERSE;
        llSetTextureAnim(mode, FACE, WINDOWS, 1, 0.0, WINDOWS, WINDOWS / SECONDS);
    }

    on_rez(integer start_param)
    {
        llResetScript();
    }
}
