// artsy slide player
// Slide: Redelivery, square 1:1
// Sheet: artsy-redelivery-square
//        each 2048 x 2048, 4 x 4 grid, 16 frames of 512 x 512
// Loop:  11.40 s in 4 runs
//
// Put the sheet on the display face and drop this script into the same prim.
// Face settings: Full Bright on, Glow 0, Alpha mode None. Repeats and offsets don't
// matter; the animation sets them.
//
// The pauses are timed here, not drawn as repeated frames, and the exit plays the
// entrance backwards. That's how a whole slide fits in 16 frames. Edit TIMELINE to
// change the timing: frame, seconds on screen.

integer FACE = ALL_SIDES;   // set your display face number if other faces have their own textures
integer COLS = 4;
integer ROWS = 4;
float   QUICK = 0.5;        // frames shorter than this are motion, played inside one run

list TIMELINE = [
     1, 0.06,   // in
     2, 0.06,   // in
     3, 0.06,   // in
     4, 0.06,   // in
     5, 0.06,   // in
     6, 0.06,   // in
     7, 0.06,   // in
     8, 4.10,   // hold: message
     9, 0.08,   // to second state
    10, 0.08,   // to second state
    11, 0.08,   // to second state
    12, 0.08,   // to second state
    13, 0.08,   // to second state
    14, 0.08,   // to second state
    15, 4.10,   // hold: second state
    14, 0.08,   // back
    13, 0.08,   // back
    12, 0.08,   // back
    11, 0.08,   // back
    10, 0.08,   // back
     9, 0.08,   // back
     8, 0.80,   // hold
     7, 0.06,   // out
     6, 0.06,   // out
     5, 0.06,   // out
     4, 0.06,   // out
     3, 0.06,   // out
     2, 0.06,   // out
     1, 0.06,   // out
     0, 0.60    // pause
];

list tiles;     // link numbers that show the slide
list runs;      // lowest frame, frame count, frames per second, seconds, backwards
integer run;

findTiles()
{
    tiles = [];
    integer n = llGetNumberOfPrims();
    if (n > 1)
    {
        integer i;
        for (i = 1; i <= n; ++i)
            if (llToLower(llGetLinkName(i)) == "tile") tiles += i;
    }
    if (llGetListLength(tiles) == 0) tiles = [LINK_THIS];
}

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
    integer i;
    integer n = llGetListLength(tiles);
    for (i = 0; i < n; ++i)
        llSetLinkTextureAnim(llList2Integer(tiles, i), mode, FACE, COLS, ROWS,
            llList2Integer(runs, run), llList2Integer(runs, run + 1), llList2Float(runs, run + 2));
    llSetTimerEvent(llList2Float(runs, run + 3));
}

default
{
    state_entry()
    {
        findTiles();
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

    changed(integer change)
    {
        if (change & CHANGED_LINK) llResetScript();
    }

    on_rez(integer start_param)
    {
        llResetScript();
    }
}
