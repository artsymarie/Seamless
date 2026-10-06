// artsy slide player
// Slide: Shine, square 1:1
// Sheet: artsy-shine-square
//        2048 x 1024, 4 x 2 grid, 8 frames of 512 x 512
// Loop:  8.56 s in 2 runs
//
// Put the sheet on the display face (1:1, for example 1 × 1 m) and drop this
// script into the same prim. Face settings: Full Bright on, Glow 0, Alpha mode None.
// Repeats and offsets don't matter; the animation sets them.
//
// Every frame is the whole slide, so it is never blank. The pauses are timed here
// instead of drawn as repeated frames, and the way back plays the move in reverse.
// Edit TIMELINE to change the timing: frame, seconds on screen.

integer FACE = ALL_SIDES;   // set your display face number if other faces have their own textures
integer COLS = 4;
integer ROWS = 2;
float   QUICK = 0.5;        // frames shorter than this are motion, played inside one run

list TIMELINE = [
     1, 0.08,   // to second state
     2, 0.08,   // to second state
     3, 0.08,   // to second state
     4, 0.08,   // to second state
     5, 0.08,   // to second state
     6, 0.08,   // to second state
     7, 3.80,   // hold: second state
     6, 0.08,   // back
     5, 0.08,   // back
     4, 0.08,   // back
     3, 0.08,   // back
     2, 0.08,   // back
     1, 0.08,   // back
     0, 3.80    // hold: first state
];

list runs;      // lowest frame, frame count, frames per second, seconds, backwards
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
        if (step < 0.04) step = 0.04;
        integer dir = 0;
        if (a + 1 < n)
        {
            integer f2 = llList2Integer(TIMELINE, (a + 1) * 2);
            if (f2 == first + 1) dir = 1;
            else if (f2 == first - 1) dir = -1;
        }
        float total = step;
        integer b = a;
        integer more = (dir != 0);
        while (more)
        {
            more = FALSE;
            if (b + 1 < n)
            {
                if (llList2Integer(TIMELINE, (b + 1) * 2) == llList2Integer(TIMELINE, b * 2) + dir)
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
                        // a run lands on a longer hold; the viewer stays on it
                        ++b;
                        total += next;
                    }
                }
            }
        }
        integer last = llList2Integer(TIMELINE, b * 2);
        integer low = first;
        if (last < low) low = last;
        runs += [low, b - a + 1, 1.0 / step, total, dir < 0];
        a = b + 1;
    }
}

play()
{
    // No LOOP flag: the viewer plays the run once and stays on its last frame.
    // A late timer only stretches a hold; it never shows a wrong frame.
    integer mode = ANIM_ON;
    if (llList2Integer(runs, run + 4)) mode = mode | REVERSE;
    llSetTextureAnim(mode, FACE, COLS, ROWS,
        llList2Integer(runs, run), llList2Integer(runs, run + 1), llList2Float(runs, run + 2));
    llSetTimerEvent(llList2Float(runs, run + 3));
}

default
{
    state_entry()
    {
        build();
        run = 0;
        play();
    }

    timer()
    {
        run += 5;
        if (run >= llGetListLength(runs)) run = 0;
        play();
    }

    on_rez(integer start_param)
    {
        llResetScript();
    }
}
