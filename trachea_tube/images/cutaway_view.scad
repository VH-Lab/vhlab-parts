use <../ferret_trachea_tube.scad>
// cut-away: remove the x > 0 half to show the bore, bevel and suture hole
difference() {
    for (i = [0:2]) translate([0, i*18, 0]) tube_variant(i);
    translate([0, -50, -1]) cube([50, 200, 100]);
}
