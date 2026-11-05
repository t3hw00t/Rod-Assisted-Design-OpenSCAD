/*
 RIBBED TPU SLEEVE — optional accessory for Rod Assisted Design
 Units: mm. This file does not modify or include the original RAD model.

 Intended starting configuration: RAD type=1, vertAngle=0, dowelDia=26,
 thickness=6, lengthLeg=50, stopperEnable=1, teardropEnable=0,
 screwAngleList=[0,180], screwDia=4, screwOffset=18.
 Check the actual printed fit; no physical strength or retention validation is claimed.
 The open sleeve does not replace the rigid RAD pole stop. TPU ribs cushion the pole;
 screws provide the original retention. Do not assume rib friction holds a loaded shelf.

 IMPORTABLE MODULE / RAD COORDINATES:
   use <Ribbed Sleeve.scad>
   ribbed_sleeve(...);
 The module's mouth is z=0. Its insertion body occupies -insertion_length..0;
 its retaining lip occupies 0..lip_thickness. Local +Z points OUT of the socket,
 exactly like a native RAD leg. Screw angle 0 points -Y; 90 points +X.
 Translate the module to the RAD mouth, then apply the existing leg rotation.
 Default side leg: mouth z=50+(26+2*6)/2=69; screw z=69-18=51;
 the 40 mm sleeve tip lands at z=29, 4 mm clear of the rigid stop at z=25.

 Standalone output is flipped and lifted for upright, lip-down printing.
 In that print orientation the mouth is z=lip_thickness and the insertion tip is
 z=lip_thickness+insertion_length. This avoids printing the lip as a hanging flange.
 The short coupon checks diameter/interference only; it deliberately omits screw holes.
*/

/* [Choose output] */
output_mode = "sleeve"; // [sleeve:Full sleeve with screw holes, fit_coupon:Short diameter fit coupon]
print_upright = true;
coupon_length = 12; // [8:1:20]

/* [Socket and bamboo measurements] */
// Match the actual RAD round dowel bore. Measure printed parts before making a full set.
socket_bore_diameter = 26; // [14:0.1:60]
// Largest measured bamboo diameter over the section that enters this sleeve.
pole_diameter = 20; // [8:0.1:50]
// DIAMETRAL clearance: sleeve outside diameter = socket bore minus this value.
diametral_fit_clearance = 0.2; // [0.1:0.05:0.8]
// Positive DIAMETRAL interference makes the unloaded rib-tip bore smaller than the pole.
diametral_interference = 0.3; // [0:0.05:0.8]
// Length inside the socket; the lip is additional and remains outside.
insertion_length = 40; // [12:1:80]

/* [Flexible wall and rounded ribs] */
// Continuous minimum outer wall, apart from the requested screw openings.
wall_thickness = 1.2; // [0.8:0.1:3]
// Zero makes a smooth bore at the SAME nominal fit diameter, for a comparison coupon.
rib_count = 8; // [0:1:24]
// Tangential width where each broad, smoothly rounded rib joins the outer wall.
rib_width = 4; // [1.5:0.1:6]
// Angle of the first rib: RAD convention, 0=-Y and 90=+X.
rib_phase_angle = 0; // [0:5:355]

/* [Mouth lip and lead-in] */
// Radial lip extension beyond the sleeve OD. It keeps the sleeve at the socket mouth.
lip_overhang = 1.2; // [0.6:0.1:3]
lip_thickness = 1.6; // [1:0.2:3]
// Ribs fade smoothly over this distance INSIDE the mouth, plus the lip thickness.
lead_in_length = 3; // [1:0.5:8]

/* [Match the RAD screw positions] */
// Empty list disables openings. 0=-Y, 90=+X, 180=+Y, 270=-X.
screw_angles = [0,180];
screw_diameter = 4; // [2:0.1:8]
// Extra DIAMETER around the screw; the sleeve is not a screw thread or clamp nut.
screw_diametral_clearance = 0.4; // [0.1:0.1:1]
screw_distance_from_mouth = 18; // [5:1:50]

/* [Check the matching stopped RAD side socket] */
// Match RAD lengthLeg. RAD increases this to at least its outside leg diameter.
rad_leg_length = 50; // [20:1:100]
// Match RAD thickness. Usable stopped depth is max(lengthLeg, outside leg diameter)-thickness.
rad_connector_wall = 6; // [3:0.5:12]
// This accessory is scoped to ROUND bores: set RAD teardropEnable=0.
rad_teardrop_enabled = false;

/* [Surface quality] */
quality = 96; // [48:16:192]

/* [Hidden] */

function rs_wrap_angle(a) = ((a % 360)+360)%360;
function rs_angle_distance(a,b) = min(rs_wrap_angle(a-b),rs_wrap_angle(b-a));
function rs_rib_weight(a,n,half_width,phase) = n==0 ? 1 :
    let(period=360/n, offset=(((a-phase+period/2)%period)+period)%period-period/2)
    abs(offset)>=half_width ? 0 : pow(cos(90*offset/half_width),2);

// A smooth, star-shaped bore loft. Cosine transitions give rounded rib tips and roots
// without offset operations changing the stated rib-tip fit diameter.
module rs_bore_void(length,lip_height,lead,base_radius,rib_height,count,width,phase,q) {
    eps=0.03;
    points_per_ring=count==0 ? q : count*max(16,ceil(q/count));
    half_width=asin(width/(2*base_radius));
    ramp_steps=8;
    levels=concat([[-length-eps,1],[-lead,1]],
        [for(k=[1:ramp_steps]) [-lead+(lead+lip_height+eps)*k/ramp_steps,pow(cos(90*k/ramp_steps),2)]]);
    rings=len(levels);
    vertices=concat(
        [for(level=levels,a=[0:points_per_ring-1])
            let(angle=360*a/points_per_ring,
                radius=base_radius-rib_height*level[1]*rs_rib_weight(angle,count,half_width,phase))
            [radius*sin(angle),-radius*cos(angle),level[0]]],
        [[0,0,levels[0][0]],[0,0,levels[rings-1][0]]]);
    bottom_center=rings*points_per_ring;
    top_center=bottom_center+1;
    sides=[for(level=[0:rings-2],i=[0:points_per_ring-1],triangle=[0:1])
        let(a=level*points_per_ring+i,b=level*points_per_ring+(i+1)%points_per_ring,
            c=(level+1)*points_per_ring+(i+1)%points_per_ring,d=(level+1)*points_per_ring+i)
        triangle==0 ? [a,b,c] : [a,c,d]];
    bottom=[for(i=[0:points_per_ring-1]) [bottom_center,(i+1)%points_per_ring,i]];
    top=[for(i=[0:points_per_ring-1]) [top_center,(rings-1)*points_per_ring+i,(rings-1)*points_per_ring+(i+1)%points_per_ring]];
    // OpenSCAD polyhedra use clockwise faces when viewed from outside.
    faces=concat(sides,bottom,top);
    polyhedron(points=vertices,faces=[for(face=faces) [for(i=[len(face)-1:-1:0]) face[i]]],convexity=12);
}

// Defaults are explicit so this module works independently through use<>.
module ribbed_sleeve(socket_bore_diameter=26,pole_diameter=20,insertion_length=40,
    diametral_fit_clearance=0.2,diametral_interference=0.3,wall_thickness=1.2,
    rib_count=8,rib_width=4,rib_phase_angle=0,lip_overhang=1.2,lip_thickness=1.6,
    lead_in_length=3,screw_angles=[0,180],screw_diameter=4,screw_diametral_clearance=0.4,
    screw_distance_from_mouth=18,rad_leg_length=50,rad_connector_wall=6,
    rad_teardrop_enabled=false,quality=96) {
    eps=0.03;
    outside_radius=(socket_bore_diameter-diametral_fit_clearance)/2;
    base_radius=outside_radius-wall_thickness;
    tip_radius=(pole_diameter-diametral_interference)/2;
    rib_height=base_radius-tip_radius;
    hole_diameter=screw_diameter+screw_diametral_clearance;
    available_depth=max(rad_leg_length,socket_bore_diameter+2*rad_connector_wall)-rad_connector_wall;
    tip_bevel=min(0.4,wall_thickness/3);
    lip_bevel=min(0.35,lip_thickness/3);
    minimum_end_ligament=1.5;

    assert(socket_bore_diameter>0 && pole_diameter>0,"Socket and pole diameters must be positive millimetres.");
    assert(diametral_fit_clearance>=0 && diametral_fit_clearance<=1,"Use 0 to 1 mm DIAMETRAL sleeve fit clearance; test a coupon.");
    assert(diametral_interference>=0 && diametral_interference<=0.8,"Use 0 to 0.8 mm DIAMETRAL interference; positive values reduce the rib-tip bore.");
    assert(wall_thickness>=0.8 && wall_thickness<outside_radius,"Outer wall must be at least 0.8 mm and smaller than the sleeve radius.");
    assert(tip_radius>=3 && base_radius>tip_radius,"Not enough space for ribs: enlarge the socket, reduce wall thickness, or use a smaller pole.");
    assert(base_radius>=pole_diameter/2+0.2,"Keep at least 0.2 mm radial relief between the nominal pole and the backing wall. Enlarge the socket, reduce wall thickness, or use a smaller pole.");
    assert(rib_count==floor(rib_count) && (rib_count==0 || (rib_count>=3 && rib_count<=24)),"rib_count must be 0 for a smooth comparison, or a whole number from 3 to 24.");
    assert(rib_width>=1.5 && rib_width<2*base_radius,"rib_width must be at least 1.5 mm and less than the base bore diameter.");
    assert(rib_count==0 || rib_height<=0.75*rib_width,"Ribs would be too tall and narrow: increase rib_width or use a closer socket size.");
    assert(rib_count==0 || 2*asin(rib_width/(2*base_radius))<=0.75*360/rib_count,"Ribs overlap or leave too little valley: reduce rib_count or rib_width.");
    assert(lip_overhang>=0.6 && lip_overhang<=rad_connector_wall,"Lip overhang must be 0.6 mm to the matching RAD wall thickness.");
    assert(lip_thickness>=1 && lip_thickness<=4,"Lip thickness must be 1 to 4 mm.");
    assert(lead_in_length>=1 && insertion_length>=lead_in_length+3,"Sleeve must extend at least 3 mm beyond its lead-in.");
    assert(lead_in_length+lip_thickness>=1.6*rib_height,"Lead-in is too steep for upright printing: increase lead_in_length.");
    assert(rad_leg_length>0 && rad_connector_wall>0,"RAD leg length and connector wall must be positive.");
    assert(!rad_teardrop_enabled,"This sleeve is scoped to round RAD bores. Set RAD teardropEnable=0 and this parameter=false.");
    assert(insertion_length>0 && insertion_length<=available_depth,
        str("Sleeve is longer than the stopped side socket: available depth is ",available_depth," mm. Shorten insertion_length."));
    assert(screw_diameter>0 && screw_diametral_clearance>=0,"Screw diameter must be positive; screw clearance cannot be negative.");
    assert(quality==floor(quality) && quality>=32 && quality<=256,"quality must be an integer from 32 to 256.");
    if(len(screw_angles)>0) {
        assert(screw_distance_from_mouth-hole_diameter/2>=lead_in_length+minimum_end_ligament,
            "Screw opening reaches the lip/lead-in. Increase screw_distance_from_mouth or reduce hole diameter.");
        assert(screw_distance_from_mouth+hole_diameter/2<=insertion_length-minimum_end_ligament,
            "Screw opening reaches the insertion tip. Increase insertion_length or move the hole toward the mouth.");
        for(i=[0:len(screw_angles)-1],j=[0:len(screw_angles)-1]) if(j>i)
            assert(2*base_radius*sin(rs_angle_distance(screw_angles[i],screw_angles[j])/2)>=hole_diameter+1,
                "Screw openings overlap or leave less than 1 mm backing-wall ligament. Separate their angles.");
    }

    difference() {
        rotate_extrude($fn=quality) polygon([
            [0,-insertion_length],[outside_radius-tip_bevel,-insertion_length],
            [outside_radius,-insertion_length+tip_bevel],[outside_radius,0],
            [outside_radius+lip_overhang,0],[outside_radius+lip_overhang,lip_thickness-lip_bevel],
            [outside_radius+lip_overhang-lip_bevel,lip_thickness],[0,lip_thickness]
        ]);
        rs_bore_void(insertion_length,lip_thickness,lead_in_length,base_radius,rib_height,
            rib_count,rib_width,rib_phase_angle,quality);
        for(angle=screw_angles)
            translate([0,0,-screw_distance_from_mouth]) rotate([90,0,angle])
                cylinder(h=outside_radius+lip_overhang+1,d=hole_diameter,$fn=quality);
    }
}

module rs_selected_output() {
    ribbed_sleeve(socket_bore_diameter=socket_bore_diameter,pole_diameter=pole_diameter,
        insertion_length=output_mode=="fit_coupon" ? coupon_length : insertion_length,
        diametral_fit_clearance=diametral_fit_clearance,diametral_interference=diametral_interference,
        wall_thickness=wall_thickness,rib_count=rib_count,rib_width=rib_width,rib_phase_angle=rib_phase_angle,
        lip_overhang=lip_overhang,lip_thickness=lip_thickness,lead_in_length=lead_in_length,
        screw_angles=output_mode=="fit_coupon" ? [] : screw_angles,screw_diameter=screw_diameter,
        screw_diametral_clearance=screw_diametral_clearance,screw_distance_from_mouth=screw_distance_from_mouth,
        rad_leg_length=rad_leg_length,rad_connector_wall=rad_connector_wall,
        rad_teardrop_enabled=rad_teardrop_enabled,quality=quality);
}

assert(output_mode=="sleeve" || output_mode=="fit_coupon","Choose sleeve or fit_coupon output_mode.");
if(print_upright) translate([0,0,lip_thickness]) rotate([180,0,0]) rs_selected_output();
else rs_selected_output();
