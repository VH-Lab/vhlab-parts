// Test print plate: all 12 ferret trachea tube designs on one labeled base.
// VH Lab. All dimensions in mm.
//
// Rows (front to back): 2.5, 3.0, 4.0 mm tip.
// Columns (left to right):
//   T5 E0  = original (5 mm taper, no extension)
//   T10 E0 = 10 mm taper
//   T5 E5  = +5 mm plain tube between barb and ribs/tab
//   T10 E5 = both
//
// Tubes stand connector-end DOWN, bevel tip UP, so nothing touches the
// tip, ribs, tab or barb. Each tube sits on 4 small breakaway pegs that
// touch only the flat exit face of the connector -- the one surface where
// a witness mark does no harm. Snap/clip each tube off at the narrow peg
// tips and sand the exit face flat.
//
// Export: openscad -o test_plate.stl test_plate.scad

use <ferret_trachea_tube.scad>

base_t      = 2;     // base plate thickness
peg_h       = 2.5;   // gap between plate and tube exit face (lets resin drain)
peg_base_d  = 1.4;
peg_tip_d   = 0.6;   // contact diameter on the tube (break point)
peg_r       = 1.75;  // pegs centred on the 0.5 mm exit wall (ID 3 / OD 4)
n_pegs      = 4;

pitch_x     = 18;
pitch_y     = 20;
label_dy    = -7;    // label position relative to tube axis
label_size  = 2.2;
label_h     = 0.6;   // embossed text height
margin      = 5;

TIPS     = ["2.5", "3.0", "4.0"];
VARIANTS = [[5, 0], [10, 0], [5, 5], [10, 5]];   // [taper_len, ext_len]

$fn = 64;

plate_x = (len(VARIANTS) - 1) * pitch_x + 2 * margin + 8;
plate_y = (len(TIPS) - 1) * pitch_y + 2 * margin + 18;
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
    label("VH Lab ferret trachea tubes  T=taper E=ext (mm)");

for (r = [0 : len(TIPS) - 1], c = [0 : len(VARIANTS) - 1]) {
    t = VARIANTS[c][0];
    e = VARIANTS[c][1];
    L = tube_length(r, t, e);
    translate([c * pitch_x, r * pitch_y, 0]) {
        // pegs
        for (k = [0 : n_pegs - 1])
            rotate(45 + k * 360 / n_pegs) translate([peg_r, 0, base_t]) peg();
        // tube, flipped so the connector exit face rests on the pegs
        translate([0, 0, base_t + peg_h + L]) rotate([0, 180, 0])
            tube_variant(r, t, e);
        // label in front of the tube
        translate([0, label_dy, base_t])
            label(str(TIPS[r], " T", t, " E", e));
    }
}
