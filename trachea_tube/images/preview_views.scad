// Preview layout of all 12 tube designs, used to render the images in this folder.
//   mode = "side"    : full tubes, viewed from +X (suture tab in profile)
//   mode = "cutaway" : x > 0 half removed to show bore, bevel and suture hole
//   mode = "3d"      : full tubes for a perspective overview
// Grouped by tip size (2.5, 3.0, 4.0 mm); within each group, left to right:
// T5 E0 (original), T10 E0, T5 E5, T10 E5.

use <../ferret_trachea_tube.scad>

mode = "side";

TIPS     = ["2.5", "3.0", "4.0"];
VARIANTS = [[5, 0], [10, 0], [5, 5], [10, 5]];
pitch    = 13;     // between tubes in a group
group    = 62;     // between size groups

function ypos(r, c) = r * group + c * pitch;

module tubes() {
    for (r = [0:2], c = [0:3])
        translate([0, ypos(r, c), 0]) tube_variant(r, VARIANTS[c][0], VARIANTS[c][1]);
}

module labels() {
    for (r = [0:2], c = [0:3])
        translate([0, ypos(r, c) + 1, -4]) rotate([90, 0, 90])
            linear_extrude(0.2) text(str("T", VARIANTS[c][0], " E", VARIANTS[c][1]),
                size = 2, halign = "center", font = "Liberation Sans:style=Bold");
    for (r = [0:2])
        translate([0, ypos(r, 1.5) + 1, -9]) rotate([90, 0, 90])
            linear_extrude(0.2) text(str(TIPS[r], " mm tip"),
                size = 3, halign = "center", font = "Liberation Sans:style=Bold");
}

if (mode == "cutaway") {
    difference() { tubes(); translate([0, -50, -1]) cube([50, 300, 100]); }
    translate([0.01, 0, 0]) labels();
} else if (mode == "side") {
    tubes();
    translate([3.2, 0, 0]) labels();
} else {
    tubes();
}
