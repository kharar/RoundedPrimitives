
/**********  How to use  **********/
//use <casing.scad>

$fn=50;
translate([0, 0, 50])
casing("front", IKEA_Vindstyrka);
casing("rear", IKEA_Vindstyrka);

translate([100, 0, 0]){
	casing("front", custom_case);
	casing("rear", custom_case);
}

/********  Design examples  ********/

IKEA_Vindstyrka = [
	 /*	0	casingSize							*/ [52, 85, 58]
	,/*	1	casingFilletR						*/ 4.5
	,/*	2	casingFilletMode				*/ 1
	,/*	3	casingWallThickness			*/ 2.25
	,/*	4	casingHoleDia						*/ 4.6
	,/*	5	casingHoleDepth					*/ 20
	,/*	6	casingHoleDistFromEdge	*/ 7
	,/*	7	clearance								*/ 0.2
	,/*	8	screwDia								*/ 2.5
	,/*	9	screwBore								*/ 2.0
	,/*10	supportThickness				*/ 0.25
	,/*11	screwtowerFull					*/ false
	,/*12	debugWindow							*/ false
];

custom_case=[
	 /* 0 casingSize							*/ [89, 134, 89]
	,/* 1 casingFilletR						*/ 10
	,/* 2 casingFilletMode				*/ 1
	,/* 3 casingWallThickness			*/ 3
	,/* 4 casingHoleDia						*/ 7
	,/* 5 casingHoleDepth					*/ 5
	,/* 6 casingHoleDistFromEdge	*/ 10
	,/* 7 clearance								*/ 0.2
	,/* 8 screwDia								*/ 3
	,/* 9 screwBore								*/ 2.6
	,/*10 supportThickness				*/ 0.25
	,/*11 screwtowerFull					*/ true
	,/*12 debugWindow							*/ false
];


/*******  How to call (end)  *******/


use<fillet.scad>
module casing(part="BOTH", settings)
{
	$casingSize							= settings[0];
	$casingFilletR					= settings[1];
	$casingFilletMode				= settings[2]; // see fillet.scad for legend
	$casingWallThickness		= settings[3];
	$casingHoleDia					= settings[4];
	$casingHoleDepth				= settings[5];
	$casingHoleDistFromEdge	= settings[6];
	$clearance							= settings[7];
	$screwDia								= settings[8];
	$screwBore							= settings[9];
	$supportThickness				=	settings[10]; // equal to expected layer height or 0 to disable support
	$screwtowerFull					= settings[11];
	$debugWindow						= settings[12];
	
	$mountingHolePositions	= [[$casingHoleDistFromEdge, $casingHoleDistFromEdge, 0],
														[$casingHoleDistFromEdge, $casingSize.y-$casingHoleDistFromEdge, 0],
														[$casingSize.x-$casingHoleDistFromEdge, $casingSize.y-$casingHoleDistFromEdge, 0],
														[$casingSize.x-$casingHoleDistFromEdge, $casingHoleDistFromEdge, 0]];

	if      (ucase(part)=="FRONT"){
		casingfront();
	} else if(ucase(part)=="REAR"){
		casingrear();
	} else if(ucase(part)=="BOTH"){
		casinghull();
	}
}

function toUpper(inputStr) = [for (c = inputStr) chr((ord(c) >= ord("a") && ord(c) <= ord("z"))?(ord(c) - ord("a") + ord("A")):ord(c))];
function join(v,i) = i>1?str(v[len(v)-i], join(v,i-1)):v[len(v)-i];
function ucase(s) = let(u=toUpper(s))	join(u, len(s));

module casingfront() {
	difference() {
		casinghull();
		casingrear_cut();
		casingMountingHoles($screwBore, $casingSize.z-$casingHoleDepth-$casingWallThickness);
		debug();
	}
}

module casingrear() {
	difference() {
		intersection() {
			casinghull();
			casingrear_cut($clearance);
		}
		translate([0, 0, $supportThickness==0?0:$casingHoleDepth+1+$supportThickness])
			casingMountingHoles($screwDia+2*$clearance, $casingSize.z-$casingHoleDepth-$casingWallThickness);
		debug();
	}
}

module casinghull() {
	difference() {
		casingouter();
		casinginner();
		debug();
	}		
}

module casingrear_cut(cutClearance=0) {
	translate([-1, -1, -1])
		cube([$casingSize.x+2, $casingSize.y+2, $casingWallThickness+$clearance-cutClearance+1]);
	casingMountingHoles($casingHoleDia+2*($casingWallThickness+$clearance-cutClearance), $casingWallThickness);
}

module casingouter(){
	difference(){
		filletcube($casingSize, $casingFilletR, $fn, $casingFilletMode);
		casingMountingHoles($casingHoleDia, 0);
	}
}

module casinginner(){
	difference(){
		translate([1, 1, 1]*$casingWallThickness)
			filletcube([$casingSize.x-2*$casingWallThickness, $casingSize.y-2*$casingWallThickness, $casingSize.z-2*$casingWallThickness], max(0, $casingFilletR-$casingWallThickness), $fn, $casingFilletMode);
		casingMountingHoles($casingHoleDia+4*($casingWallThickness+$clearance), max($casingWallThickness, $screwtowerFull?$casingSize.z-$casingHoleDepth:$casingWallThickness*3+$clearance));
		if(!$screwtowerFull)
			for(p=[0:3])
				translate($mountingHolePositions[p])
					rotate([0, 0, -90*p+45+180])
						translate([0, 0, $casingHoleDepth+$casingWallThickness*3+$clearance])
							hull() {
								cylinder(d=$casingHoleDia+4*($casingWallThickness+$clearance), h=0.01);
								translate([100, 0, 100])
									cylinder(d=$casingHoleDia+4*($casingWallThickness+$clearance), h=0.01);
							}
	}
}

module casingMountingHoles(d=0, lenAdd=0) {
	translate([0, 0, -1])
		for(p=$mountingHolePositions)
			translate(p)
				cylinder(d=d, h=$casingHoleDepth+lenAdd+1);
}

module debug() {
	if ($debugWindow)
		translate([-1, -1, -1])
			cube([$casingHoleDistFromEdge+1, $casingSize.y+2, $casingSize.z+2]);
}
