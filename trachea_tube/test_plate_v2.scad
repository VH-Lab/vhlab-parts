// Test print plate V2: ferret trachea tubes, all with the +5 mm extension (E5).
// VH Lab. All dimensions in mm.
//
// Changes from V1 (test_plate.scad):
//   - E0 designs dropped; every tube has 5 mm of plain tube before the barb.
//   - New tip sizes 2.0 and 3.5 mm added alongside 2.5, 3.0 and 4.0 mm.
//
// Columns (left to right): 2.0, 2.5, 3.0, 3.5, 4.0 mm tip.
// Rows (front to back):    T5 (5 mm taper), T10 (10 mm taper).
//
// Tubes stand connector-end DOWN, bevel tip UP, so nothing touches the
// tip, ribs, tab or barb. Each tube sits on 6 small breakaway pegs that
// touch only the flat exit face of the connector -- the one surface where
// a witness mark does no harm. Snap/clip each tube off at the narrow peg
// tips and sand the exit face flat.
//
// Export: openscad -o test_plate_v2.stl test_plate_v2.scad

use <ferret_trachea_tube.scad>

base_t      = 2;     // base plate thickness
peg_h       = 2.5;   // gap between plate and tube exit face (lets resin drain)
peg_base_d  = 1.5;   // 6 pegs on r=1.75 are 1.75 apart: keep gaps for drainage
peg_tip_d   = 0.8;   // contact diameter on the tube (break point)
peg_r       = 1.75;  // pegs centred on the 0.5 mm exit wall (ID 3 / OD 4)
n_pegs      = 6;

pitch_x     = 18;
pitch_y     = 20;
label_dy    = -7;    // label position relative to tube axis
label_size  = 2.2;
label_h     = 0.6;   // embossed text height
margin      = 5;

// [label, index into SIZES in ferret_trachea_tube.scad], smallest first
TIPS    = [["2.0", 3], ["2.5", 0], ["3.0", 1], ["3.5", 4], ["4.0", 2]];
TAPERS  = [5, 10];
EXT     = 5;

$fn = 64;

plate_x = (len(TIPS) - 1) * pitch_x + 2 * margin + 8;
plate_y = (len(TAPERS) - 1) * pitch_y + 2 * margin + 18;
x0 = -margin - 4;
y0 = label_dy - margin - 2;

module label(t) {
    linear_extrude(label_h)
        text(t, size = label_size, halign = "center", valign = "center",
             font = "Liberation Sans:style=Bold");
}

module peg() {
    cylinder(d1 = peg_base_d, d2 = peg_tip_d, h = peg_h + 0.01);
}

// base plate with chamfered bottom edge (easier to pry off the platform)
translate([x0, y0, 0]) hull() {
    translate([0.6, 0.6, 0]) cube([plate_x - 1.2, plate_y - 1.2, base_t]);
    translate([0, 0, 0.6]) cube([plate_x, plate_y, base_t - 0.6]);
}
// title
translate([x0 + plate_x / 2, y0 + plate_y - 3.5, base_t])
    label("VH Lab ferret trachea tubes V2  T=taper E=ext");

for (c = [0 : len(TIPS) - 1], r = [0 : len(TAPERS) - 1]) {
    i = TIPS[c][1];
    t = TAPERS[r];
    L = tube_length(i, t, EXT);
    translate([c * pitch_x, r * pitch_y, 0]) {
        // pegs
        for (k = [0 : n_pegs - 1])
            rotate(k * 360 / n_pegs) translate([peg_r, 0, base_t]) peg();
        // tube, flipped so the connector exit face rests on the pegs
        translate([0, 0, base_t + peg_h + L]) rotate([0, 180, 0])
            tube_variant(i, t, EXT);
        // label in front of the tube
        translate([0, label_dy, base_t])
            label(str(TIPS[c][0], " T", t, " E", EXT));
    }
}
