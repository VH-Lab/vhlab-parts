use <../ferret_trachea_tube.scad>
// three tubes stacked along X so they can be viewed from +X (tab profile)
for (i=[0:2]) translate([0, i*18, 0]) tube_variant(i);
