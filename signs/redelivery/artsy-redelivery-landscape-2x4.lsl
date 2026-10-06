// artsy kinetic sign player
// Sign:  Redelivery, landscape 2:1
// Sheet: artsy-redelivery-landscape-2x4
//        2048 x 2048 px, 2 x 4 grid, 8 frames of 1024 x 512
// Loop:  10.16 s in 5 runs
//
// 1. Put the spritesheet on the display face: Full Bright on, Glow 0, Alpha mode None.
//    Repeats and offsets don't matter; the animation sets them.
// 2. Drop this script into the same prim. It starts on its own.
//
// Holds are timed here instead of repeating frames in the sheet. That is what keeps
// the sheet at 8 frames. To change timing, edit TIMELINE: frame, seconds on screen.

integer FACE = ALL_SIDES;   // set your display face number if other faces have their own textures
integer COLS = 2;
integer ROWS = 4;
float   QUICK = 0.5;        // frames shorter than this are cuts, played inside one run

list TIMELINE = [
    0, 1.10,   // redelivery
    1, 0.12,   // glitch
    2, 0.12,   // scroll
    3, 2.50,   // step 1
    4, 2.50,   // step 2
    5, 0.12,   // flash
    6, 1.30,   // that's it
    7, 2.40    // collections
];

list runs;      // first frame, frame count, frames per second, seconds
integer run;

build()
{
    runs = [];
    integer n = llGetListLength(TIMELINE) / 2;
    integer a = 0;
    while (a < n)
    {
        integer first = llList2Integer(TIMELINE, a * 2);
        float step = llList2Float(TIMELINE, a * 2 + 1);
        if (step < 0.05) step = 0.05;
        float total = step;
        integer b = a;
        integer more = TRUE;
        while (more)
        {
            more = FALSE;
            if (b + 1 < n)
            {
                if (llList2Integer(TIMELINE, (b + 1) * 2) == first + b + 1 - a)
                {
                    float next = llList2Float(TIMELINE, (b + 1) * 2 + 1);
                    if (next == llList2Float(TIMELINE, a * 2 + 1))
                    {
                        ++b;
                        total += next;
                        more = TRUE;
                    }
                    else if (next > step && next >= QUICK)
                    {
                        // a run of cuts lands on a longer hold; the viewer stays on it
                        ++b;
                        total += next;
                    }
                }
            }
        }
        runs += [first, b - a + 1, 1.0 / step, total];
        a = b + 1;
    }
}

play()
{
    // No LOOP flag: the viewer plays the run once and stays on its last frame.
    // A late timer only stretches a hold; it never shows the wrong frame.
    llSetTextureAnim(ANIM_ON, FACE, COLS, ROWS,
        llList2Integer(runs, run), llList2Integer(runs, run + 1), llList2Float(runs, run + 2));
    llSetTimerEvent(llList2Float(runs, run + 3));
}

default
{
    state_entry()
    {
        build();
        run = 0;
        if (llGetListLength(runs) == 4)
        {
            // one even run: let the viewer loop it, no timer needed
            llSetTimerEvent(0.0);
            llSetTextureAnim(ANIM_ON | LOOP, FACE, COLS, ROWS,
                llList2Integer(runs, 0), llList2Integer(runs, 1), llList2Float(runs, 2));
        }
        else play();
    }

    timer()
    {
        run += 4;
        if (run >= llGetListLength(runs)) run = 0;
        play();
    }

    on_rez(integer start_param)
    {
        llResetScript();
    }
}
