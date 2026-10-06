// artsy spinning badge: one texture, smooth rotation, no frames
// Texture: artsy-badge-512 (transparent corners).
// Face settings: Alpha mode Alpha masking (cutoff 128), Full Bright on,
// Repeats 1 x 1, Offset 0, Rotation 0.

integer FACE    = ALL_SIDES;  // set your display face number if other faces have their own textures
float   SECONDS = 16.00;    // one full turn; make it negative to spin the other way

default
{
    state_entry()
    {
        llSetTextureAnim(ANIM_ON | SMOOTH | ROTATE | LOOP, FACE, 1, 1, 0.0, TWO_PI, TWO_PI / SECONDS);
    }

    on_rez(integer start_param)
    {
        llResetScript();
    }
}
