//USAGE:
//use<chamfer.scad>
//
//Syntax:
//  chamfercube([x, y, z], chamfer, mode, center);
//  chamfercylinder(h, r, chamfer, mode, center);
//
// Built-in epsilon along the z-axis for subtractional modes


              // CHECK CENTERS
							
$epsilon=.01;
							
							
/**** DEMO ****/
demo=[8, 10, 12];

// modes
for(mode=[0, 1, 2]){
	translate([2*demo.x*mode+demo.x/2, 7*demo.y, 0])
		difference(){
			translate([-demo.x, -demo.y, 0])
				cube([2*demo.x, 2*demo.y, demo.z]);
			chamfercylinder(h=12, r=4, mode=mode, chamfer=-1);
		}

	translate([2*demo.x*mode+demo.x/2, 5*demo.y, 0])
		chamfercylinder(h=12, r=4, mode=mode, chamfer=1);

	translate([2*demo.x*mode, 2*demo.y, 0])
		difference(){
			translate([-demo.x/2, -demo.y/2, 0])
				cube([2*demo.x, 2*demo.y, demo.z]);
			chamfercube(size=demo, mode=mode, chamfer=-1);
		}

	translate([2*demo.x*mode, 0*demo.y, 0])
		chamfercube(size=demo, mode=mode, chamfer=1);

	translate([2*demo.x*mode+demo.x/2, -10])
		linear_extrude(1)
			text(str(mode), halign="center");
}
translate([0, -10])
	linear_extrude(1)
		text("mode: ", halign="right");


// (mode=3) corners
translate([0, -6*demo.y, 0]){
	for(corner=[0, 1, 2]){
		translate([2*demo.x*corner, 2*demo.y, 0])
			difference(){
				translate([-demo.x/2, -demo.y/2, 0])
					cube([2*demo.x, 2*demo.y, demo.z]);
				chamfercube(size=demo, mode=2, chamfer=-1, corner=corner);
			}

		translate([2*demo.x*corner, 0*demo.y, 0])
			chamfercube(size=demo, mode=2, chamfer=1, corner=corner);

		translate([2*demo.x*corner+demo.x/2, -10])
			linear_extrude(1)
				text(str(corner), halign="center");
	}
	translate([0, -10])
		linear_extrude(1)
			text("corner: ", halign="right");
}
/***************/

/*
$vpr = [35, 0, 40];
$vpt = [40, 25, 0];
$vpd = 200;
$vpf = 25;
*/
$fn=50;

module chamfercylinder(h=10, r=10, chamfer=1, mode=2, center=false){
	translate([0, 0, center?-h/2:0]){
		if (mode==0)
			translate([0, 0, center?0:(chamfer<0?-$epsilon:0)])
				cylinder(h=h+(chamfer<0?2*$epsilon:0), r=r);
		else if (mode==1)
			rotate_extrude(convexity = 10)
				polygon([[0, 0-(chamfer<0?$epsilon:0)] ,[r-chamfer, 0-(chamfer<0?$epsilon:0)], [r, abs(chamfer)-(chamfer<0?$epsilon:0)], [r, h-abs(chamfer)+(chamfer<0?$epsilon:0)], [r-chamfer, h+(chamfer<0?$epsilon:0)], [0, h+(chamfer<0?$epsilon:0)]]);
	}
}

module chamfercube(size=[10, 10, 10], chamfer=1, mode=4, corner=0, center=false){
	if      (mode==0) // regular (no chamfer)
		translate([0, 0, center?0:(chamfer<0?-$epsilon:0)])
			cube(size+[0, 0, chamfer<0?2*$epsilon:0], center=center);
	else if (mode==1) // faces (top + bottom)
		__chamferface(size=size, chamfer=chamfer, center=center);
	else if (mode==2) // full
		__chamfercubeselector(size=size, chamfer=chamfer, corner=corner, center=center);
//	else if (mode==3) // full with corners
//		__chamfercubecorners(size=size, chamfer=chamfer, center=center);
//	else if (mode==4) // full with hex corners
//		__chamfercubecornerhex(size=size, chamfer=chamfer, center=center);
}

module chamfertransition(size=[10, 10], chamfer=-1, alpha=0.5){
	polyhedron([
		[-chamfer, 0, -chamfer],
		[size[0]+chamfer, 0, -chamfer],
		[size[0], -chamfer, -chamfer],
		[size[0], size[1]+chamfer, -chamfer],
		[size[0]+chamfer, size[1], -chamfer],
		[-chamfer, size[1], -chamfer],
		[0, size[1]+chamfer, -chamfer],
		[0, -chamfer, -chamfer],
		
		[-chamfer*alpha, chamfer, 0],
		[size[0]+chamfer*alpha, chamfer, 0],
		[size[0]-chamfer, -chamfer*alpha, 0],
		[size[0]-chamfer, size[1]+chamfer*alpha, 0],
		[size[0]+chamfer*alpha, size[1]-chamfer, 0],
		[-chamfer*alpha, size[1]-chamfer, 0],
		[chamfer, size[1]+chamfer*alpha, 0],
		[chamfer, -chamfer*alpha, 0]
	],[
		[7, 6, 5, 4, 3, 2, 1, 0],
		[8, 9, 10, 11, 12, 13, 14, 15],
		[0, 1, 9, 8],
		[1, 2, 10, 9],
		[2, 3, 11, 10],
		[3, 4, 12, 11],
		[4, 5, 13, 12],
		[5, 6, 14, 13],
		[6, 7, 15, 14],
		[7, 0, 8, 15]
	]);
}

module chamfercorners(size=[10, 10, 10], chamfer=1, center=false){
		translate(size/2)
		for(x=[0, 1], y=[0, 1], z=[0, 1])
			mirror([x, 0, 0]) mirror([0, y, 0]) mirror([0, 0, z])
				polyhedron([
					[size[0]/2, size[1]/2, size[2]/2],
					[size[0]/2, size[1]/2-chamfer, size[2]/2-chamfer],
					[size[0]/2-chamfer, size[1]/2-chamfer, size[2]/2],
					[size[0]/2-chamfer, size[1]/2, size[2]/2-chamfer]
				], [
					[0, 3, 1],
					[1, 3, 2],
					[2, 0, 1],
					[3, 0, 2]
				]);
}

module chamfercornerhex(size=[10, 10, 10], chamfer=1, corner=1, center=false){
	translate(size/2)
		for(x=[0, 1], y=[0, 1], z=[0, 1])
			mirror([x, 0, 0]) mirror([0, y, 0]) mirror([0, 0, z])
				polyhedron([
					[size[0]/2+.1, size[1]/2+.1, size[2]/2+.1],
					[size[0]/2, size[1]/2-2*chamfer, size[2]/2-chamfer],
					[size[0]/2, size[1]/2-chamfer, size[2]/2-2*chamfer],
					[size[0]/2-chamfer, size[1]/2, size[2]/2-2*chamfer],
					[size[0]/2-2*chamfer, size[1]/2, size[2]/2-chamfer],
					[size[0]/2-2*chamfer, size[1]/2-chamfer, size[2]/2],
					[size[0]/2-chamfer, size[1]/2-2*chamfer, size[2]/2]
				], [
					[1, 2, 3, 4, 5, 6],
					[2, 1, 0],
					[3, 2, 0],
					[4, 3, 0],
					[5, 4, 0],
					[6, 5, 0],
					[1, 6, 0]
				]);
}

module chamfersquare(size=[5, 5], chamfer=1, center=false){
	translate(center?-size/2 : [0, 0])
		polygon([
			[-size[0]/2+abs(chamfer), -size[1]/2],
			[+size[0]/2-abs(chamfer), -size[1]/2],
			[+size[0]/2, -size[1]/2+chamfer],
			[+size[0]/2, +size[1]/2-chamfer],
			[+size[0]/2-abs(chamfer), +size[1]/2],
			[-size[0]/2+abs(chamfer), +size[1]/2],
			[-size[0]/2, +size[1]/2-chamfer],
			[-size[0]/2, -size[1]/2+chamfer]
		]);
}

module __chamfersides(size=[10, 20, 5], chamfer=1, center=false){
	for (v=[0:1]) if (size[v]-2*chamfer < 0) echo (str("Value of size[",v,"] is too small for chamfer value"));
	translate(center?[0, 0, 0] : size/2)
		linear_extrude(size[2], center=true, convexity=2)
			chamfersquare([size[0], size[1]], chamfer=chamfer);
}

// 1
module __chamferface(size=[25, 50, 8], chamfer=1, center=false){
	for (v=[0:2]) if (size[v]-2*chamfer < 0) echo (str("Value of size[",v,"] is too small for chamfer value"));
	translate(center?[0, 0, 0] : size/2)
		intersection(){
				rotate([0, 90, 0])
					__chamfersides(size=[size[2]+(chamfer<0?2*$epsilon:0), size[1], 2*size[0]], chamfer=chamfer, center=true);
				rotate([0, 90, 90])
					__chamfersides(size=[size[2]+(chamfer<0?2*$epsilon:0), size[0], 2*size[1]], chamfer=chamfer, center=true);
		}
}

// 2
module __chamfercubeselector(size=[26, 50, 10], chamfer=7, corner=0, center=false){
	if(chamfer>=0){
		if(corner<1)
			__chamfercube(size=size, chamfer=chamfer, center=center);
		if(corner==1)
			difference(){
				__chamfercube(size=size, chamfer=chamfer, center=center);
				chamfercorners(size=size, chamfer=chamfer, center=center);
			}
		if(corner>1)
		difference(){
			__chamfercube(size=size, chamfer=chamfer, center=center);
			chamfercornerhex(size=size, chamfer=chamfer, center=center);
		}
	}
	else
		translate(center?-size/2 : [0, 0, 0])
			union(){
				translate([0, 0, -$epsilon])
					__chamfersides(size+[0, 0, 2*$epsilon], abs(chamfer));
				translate([0, 0, size[2]/2])
					for(z=[0, 1])
						mirror([0, 0, z])
							translate([0, 0, -size[2]/2-$epsilon])
								chamfertransition(size=size+[0, 0, 2*$epsilon], chamfer=chamfer, alpha=corner/2);
			}
}

module __chamfercube(size=[26, 50, 10], chamfer=7, corner=0, center=false){
	if(chamfer>=0)
		intersection(){
			__chamfersides(size, chamfer, center=center);
			__chamferface(size, chamfer, center=center);
		}
}
