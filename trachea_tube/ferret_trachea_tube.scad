// Ferret trachea (intubation) tube family -- VH Lab
// Parametric OpenSCAD model. All dimensions in mm.
//
// Coordinate system: tube axis = Z. Insertion tip (bevel) at z = 0,
// respirator connector (barb) at z = total length.
//
// Choose a design from the command line, e.g.:
//   openscad -D variant=2 -D taper_len=10 -D ext_len=5 -o out.stl ferret_trachea_tube.scad
//
// variant  : 0 = 2.5 mm tip, 1 = 3.0 mm tip, 2 = 4.0 mm tip,
//            -1 = show all three side by side (viewing only)
// taper_len: length of the taper behind the tip (5 = original, 10 = long taper).
//            A longer taper pushes the ribs/tab/barb back and adds to the length.
// ext_len  : extra plain tube inserted between the barb and the ribs/tab
//            (0 = original, 5 = +5 mm). Ribs and tab stay at the same
//            distance from the tip; the tube gets longer at the connector end.
//
// Base lengths (taper_len = 5, ext_len = 0):
//   2.5 mm tip: 25 mm, no ribbing, suture tab 15 mm from tip
//   3.0 mm tip: 30 mm, ribbed,     suture tab 20 mm from tip
//   4.0 mm tip: 30 mm, ribbed,     suture tab 20 mm from tip

variant   = -1;
taper_len = 5;
ext_len   = 0;

// ---------------- shared parameters ----------------
wall          = 0.5;   // wall thickness everywhere
tip_len       = 5;     // straight tip section from insertion end
bevel_angle   = 45;    // insertion bevel (degrees from tube axis)

conn_od       = 4;     // respirator connector OD (ID = conn_od - 2*wall)
barb_od       = 5;     // barb maximum OD
barb_len      = 5;     // barb occupies the last 5 mm
barb_flat     = 2;     // straight 4 mm OD lead-in at the exit
neck_len      = 1;     // 4 mm OD neck just behind the barb shoulder

rib_pitch     = 1;     // ribs: 1 mm raised, 1 mm groove
rib_height    = 0.5;   // radial rib height (OD grows by 1 mm)
rib_ramp      = 0.6;   // axial length of the sloped tip-facing side of each rib

tab_rise      = 3;     // tab height above the tube surface
tab_len       = 6;     // tab length along the tube
tab_thick     = 1.5;   // tab thickness
tab_hole_d    = 2;     // suture hole diameter

$fn = 96;

// [tip OD, body OD, base length, ribbed?, base suture tab centre from tip (0 = none)]
// (base = values for taper_len = 5, ext_len = 0)
SIZES = [
    [2.5, 3.5, 25, false, 15],
    [3.0, 4.0, 30, true,  20],
    [4.0, 5.0, 30, true,  20],
];

// ---------------- geometry ----------------
// total length of a design
function tube_length(i, taper = 5, ext = 0) = SIZES[i][2] + (taper - 5) + ext;

module trachea_tube(tip_od, body_od, L0, ribbed, tab0, expand_len = 5, ext = 0) {
    L   = L0 + (expand_len - 5) + ext;          // total length
    tab = tab0 > 0 ? tab0 + (expand_len - 5) : 0; // tab moves with the ribs
    rt = tip_od / 2;
    rm = body_od / 2;
    rr = rm + rib_height;
    rc = conn_od / 2;
    rb = barb_od / 2;
    z_body  = tip_len + expand_len;     // start of body
    z_neck  = L - barb_len - neck_len;  // body ends, neck begins
    z_barb  = L - barb_len;             // barb shoulder
    z_feat  = z_neck - ext;             // end of ribbed region (plain tube after)

    n_rib = ribbed ? floor((z_feat - z_body) / (2 * rib_pitch)) : 0;
    // each rib: sloped tip-facing side (rm -> rr over rib_ramp) so the tube
    // slides in, square back side to hold the tie. The first rib needs no
    // slope because the taper already runs up to the rib OD.
    ribs = [ for (i = [0 : n_rib - 1]) each [
        [rr, z_body + 2*i*rib_pitch + (i == 0 ? 0 : rib_ramp)],
        [rr, z_body + (2*i + 1)*rib_pitch],
        [rm, z_body + (2*i + 1)*rib_pitch],
        [rm, z_body + (2*i + 2)*rib_pitch] ] ];

    outer = concat(
        // on ribbed tubes the taper runs out to the rib OD, flush with the
        // first rib, so the tube slides in without catching on that rib
        [[0, 0], [rt, 0], [rt, tip_len]],
        ribbed ? ribs : [[rm, z_body]],
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
            if (tab > 0) suture_tab(ribbed ? rr : rm, tab);
        }
        rotate_extrude() polygon(inner);
        // 45 degree bevel at the insertion tip (long point on the tab side)
        translate([0, rt, 0]) rotate([-(90 - bevel_angle), 0, 0])
            translate([-50, -50, -100]) cube(100);
    }
}

// Fin along the tube on the +Y side with a transverse hole for suture.
// The hole sits right against the tube surface (its bottom edge is flush
// with the outer surface / rib tops) so the suture pulls toward the
// animal with minimal lever arm (no rotational torque on the tube).
module suture_tab(r_surf, z_pos) {
    hole_y = r_surf + tab_hole_d / 2;         // hole bottom flush with surface
    r_top = r_surf + tab_rise - hole_y;       // rounded top concentric w/ hole
    translate([0, 0, z_pos]) difference() {
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

module tube_variant(i, taper = 5, ext = 0) {
    s = SIZES[i];
    trachea_tube(s[0], s[1], s[2], s[3], s[4], taper, ext);
}

if (variant < 0) {
    for (i = [0 : len(SIZES) - 1])
        translate([i * 15, 0, 0]) tube_variant(i, taper_len, ext_len);
} else {
    tube_variant(variant, taper_len, ext_len);
}
