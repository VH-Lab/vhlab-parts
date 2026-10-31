// Ferret trachea (intubation) tube family -- VH Lab
// Parametric OpenSCAD model. All dimensions in mm.
//
// Coordinate system: tube axis = Z. Insertion tip (bevel) at z = 0,
// respirator connector (barb) at z = total length.
//
// Select a size with the `variant` parameter, e.g. from the command line:
//   openscad -D variant=0 -o tube_2.5mm.stl ferret_trachea_tube.scad
// variant = 0 : 2.5 mm tip, 25 mm long, no ribbing, no suture tab
// variant = 1 : 3.0 mm tip, 30 mm long, ribbed, suture tab
// variant = 2 : 4.0 mm tip, 30 mm long, ribbed, suture tab
// variant = -1: show all three side by side (for viewing only)

variant = -1;

// ---------------- shared parameters ----------------
wall          = 0.5;   // wall thickness everywhere
tip_len       = 5;     // straight tip section from insertion end
expand_len    = 5;     // length of the taper from tip OD to body OD
bevel_angle   = 45;    // insertion bevel (degrees from tube axis)

conn_od       = 4;     // respirator connector OD (ID = conn_od - 2*wall)
barb_od       = 5;     // barb maximum OD
barb_len      = 5;     // barb occupies the last 5 mm
barb_flat     = 2;     // straight 4 mm OD lead-in at the exit
neck_len      = 1;     // 4 mm OD neck just behind the barb shoulder

rib_pitch     = 1;     // ribs: 1 mm raised, 1 mm groove
rib_height    = 0.5;   // radial rib height (OD grows by 1 mm)

tab_pos       = 20;    // suture tab centre, distance from tip
tab_rise      = 5;     // tab height above the tube surface
tab_len       = 6;     // tab length along the tube
tab_thick     = 1.5;   // tab thickness
tab_hole_d    = 2;     // suture hole diameter

$fn = 96;

// [tip OD, body OD, total length, ribbed?, suture tab?]
SIZES = [
    [2.5, 3.5, 25, false, false],
    [3.0, 4.0, 30, true,  true ],
    [4.0, 5.0, 30, true,  true ],
];

// ---------------- geometry ----------------
module trachea_tube(tip_od, body_od, L, ribbed, tab) {
    rt = tip_od / 2;
    rm = body_od / 2;
    rr = rm + rib_height;
    rc = conn_od / 2;
    rb = barb_od / 2;
    z_body  = tip_len + expand_len;     // start of body
    z_neck  = L - barb_len - neck_len;  // body ends, neck begins
    z_barb  = L - barb_len;             // barb shoulder

    n_rib = ribbed ? floor((z_neck - z_body) / (2 * rib_pitch)) : 0;
    ribs = [ for (i = [0 : n_rib - 1]) each [
        [rr, z_body + 2*i*rib_pitch],
        [rr, z_body + (2*i + 1)*rib_pitch],
        [rm, z_body + (2*i + 1)*rib_pitch],
        [rm, z_body + (2*i + 2)*rib_pitch] ] ];

    outer = concat(
        [[0, 0], [rt, 0], [rt, tip_len], [rm, z_body]],
        ribbed ? ribs : [],
        [[rm, z_neck], [rc, z_neck], [rc, z_barb],
         [rb, z_barb], [rc, L - barb_flat], [rc, L], [0, L]]);

    // bore: constant wall under tip/body (groove diameter), connector ID
    // at the barb. Transition placed where the wall stays >= 0.5 mm.
    ri = rm - wall;
    rci = rc - wall;
    zt0 = (ri > rci) ? z_neck - 2 : z_neck;
    zt1 = (ri > rci) ? z_neck     : z_barb;
    inner = [[0, -1], [rt - wall, -1], [rt - wall, tip_len], [ri, z_body],
             [ri, zt0], [rci, zt1], [rci, L + 1], [0, L + 1]];

    difference() {
        union() {
            rotate_extrude() polygon(outer);
            if (tab) suture_tab(ribbed ? rr : rm);
        }
        rotate_extrude() polygon(inner);
        // 45 degree bevel at the insertion tip (long point on the tab side)
        translate([0, rt, 0]) rotate([-(90 - bevel_angle), 0, 0])
            translate([-50, -50, -100]) cube(100);
    }
}

// Fin along the tube on the +Y side with a transverse hole for suture.
module suture_tab(r_surf) {
    r_top = tab_len / 2;                      // rounded top
    hole_y = r_surf + tab_rise - r_top;
    translate([0, 0, tab_pos]) difference() {
        hull() {
            translate([-tab_thick/2, 0, -tab_len/2])
                cube([tab_thick, hole_y, tab_len]);
            translate([0, hole_y, 0]) rotate([0, 90, 0])
                cylinder(r = r_top, h = tab_thick, center = true);
        }
        translate([0, hole_y, 0]) rotate([0, 90, 0])
            cylinder(d = tab_hole_d, h = tab_thick + 2, center = true, $fn = 48);
    }
}

module tube_variant(i) {
    s = SIZES[i];
    trachea_tube(s[0], s[1], s[2], s[3], s[4]);
}

if (variant < 0) {
    for (i = [0 : len(SIZES) - 1])
        translate([i * 15, 0, 0]) tube_variant(i);
} else {
    tube_variant(variant);
}
