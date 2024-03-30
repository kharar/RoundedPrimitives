// Rounded corners module
// Author: ElectroMan (kharar@gmail.com)
//
// Creates a rounded corner from three specified radii
//
// Todo:
//	*	Create demo script
//	*	Accept 2/3 inverted corners for subtraction
//	*	Idea: implement edge/corner subtraction (3D) using invertface=[x0, x1, y0, y1, z0, z1]
//	*	Optimize sides code into a for() loop
//	* Add epsilon to smooth_corner x&y axis
//
// Someone else trying to acomplish the same:
// https://stackoverflow.com/questions/72537595/3d-cube-with-individually-rounded-corners
// https://github.com/rcolyer/smooth-prim/

// Some interresting code:
// https://homehack.nl/twisted-vase-in-openscad/

*roundcube(size=20, r=[[1, 2, 3, 4], [2, 3, 4, 1], [3, 4, 1, 2]]);
roundcube(r=[1, 1, 2]);
*roundcube(size=15, r=[1, 1, [5, 3, 5, 5]]);
*roundcube(r=[[1, 1, 1, 0], [0, 1, 2, 2], [1, 0, 1, 0]]);
*difference(){
	roundcube(size=[71, 150, 20], r=[3, 3, 17]);
	cube([71, 150, 20], center=true);
}


*roundcube(size=[10, 10, 10], r=[1, 1, 6]);											// fails r+r>size
*roundcube(size=[12, 10, 15], r=[1, 1, [1, 7, 1, 7]]);					// fails filling
*roundcube(r=[0, 0, 1]);																				// fails filling
*roundcube(r=[[1, 2, 3, 1], [2, 2, 1, 1], [1, .3, 2, 1]]);			// fails x3, y3, z1 edge seams

/*
size=[12, 10, 15];
r=[
			[1, 2, 3, 1],
			[3, 2, 1, 1],
			[2, 3, 2, 1]
	];
*/


*roundcube(size=size, r=r, $fn=20);

//
// The r parameter can take two main forms
//   r=[rx, ry, rz]
// Each of the sub parameters rx, ry and rz define the radius along the edges of corresponding axis
// These sub parameters can be individually expanded
//   r=[[rx1, rx2, rx3, rx4], ry, rz]
//   r=[rx, [ry1, ry2, ry3, ry4], rz]
//   r=[rx, ry, [rz1, rz2, rz3, rz4]]
//   r=[[rx1, rx2, rx3, rx4], [ry1, ry2, ry3, ry4], [rz1, rz2, rz3, rz4]]
// The numbering scheme 1, 2, 3, 4 begins with the edge which is closest to corresponding axis and follows the right hand rule, where thumb pointing along the axis, the fingers curl around indicating the order of edges.
//
module roundcube(size=10, r=1, $fn=20, epsilon=.001){
	size=is_list(size)?size:is_num(size)?[size, size, size]:[1, 1, 1];
	assert(len(size)>=3,"ERROR in roundcube(), parameter size[n] too short!");
	//ensure r is a valid 3x4 list before proceeding
	r0=!(is_list(r)&&len(r)>=3)?(!is_num(r))||is_undef(r)?[[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]]:[r, r, r]:r;
	r=[
		is_list(r0.x)?len(r0.x)==4?r0.x:r0.x[0]*[1, 1, 1, 1]:r0.x*[1, 1, 1, 1],
		is_list(r0.y)?len(r0.y)==4?r0.y:r0.y[0]*[1, 1, 1, 1]:r0.y*[1, 1, 1, 1],
		is_list(r0.z)?len(r0.z)==4?r0.z:r0.z[0]*[1, 1, 1, 1]:r0.z*[1, 1, 1, 1]
		];

	//echo(r0=r0, r=r)
	//echo([for(s=r) for(t=s) t][0]);  // initial value of flattened r
	//assert(false, "stop");
	
	//error handling
	assert(len(r.x)>=4,"ERROR in roundcube(), parameter r.x[n] too small!");
	assert(len(r.y)>=4,"ERROR in roundcube(), parameter r.y[n] too small!");
	assert(len(r.z)>=4,"ERROR in roundcube(), parameter r.z[n] too small!");
	
	//edges
	erm=[[0, 0, 3, 1], [0, 3, 3, 2], [1, 3, 2, 2], [1, 0, 2, 1]];							// edge rotation matrix, indexes for bottom/top corner radius
	translate(size/2)																													// to cube center
	for(a=[0:2], i=[0:3])
		let(
			bot=max(r[(a+1)%3][erm[i][0]], r[(a+2)%3][erm[i][1]])-epsilon,
			top=max(r[(a+1)%3][erm[i][2]], r[(a+2)%3][erm[i][3]])-epsilon)
//			bot=max(r[a][i], r[(a+1)%3][erm[i][0]], r[(a+2)%3][erm[i][1]])-epsilon,
//			top=max(r[a][i], r[(a+1)%3][erm[i][2]], r[(a+2)%3][erm[i][3]])-epsilon)
		{
			rotate(a==0?[90, 0, 90]:a==1?[-90, -90, 0]:0)													// select current axis
				rotate([0, 0, i*90]) translate(-[size[(a+(i%2?2:1))%3], size[(a+(i%2?1:2))%3], size[a]]/2)															// move to current iteration
					translate([0, 0, bot]) edge(size[a]-(bot+top), r[a][i], $fn=2*$fn);	// draw edge
		}
	
	//corners
	crm=[[0, 0, 0], [0, 3, 1], [1, 0, 3], [1, 3, 2], [3, 1, 0], [3, 2, 1], [2, 1, 3], [2, 2, 2]];	// corner rotation matrix, indexes for adjacent edges
	for(i=[0: 7])
		let(x=i%2, y=floor(i/2)%2, z=floor(i/4)%2)
		translate([x*size.x, y*size.y, z*size.z])
			mirror([0, 0, z==1?1:0]) mirror([0, y==1?1:0, 0]) mirror([x==1?1:0, 0, 0]){
//				roundedcorner([r.x[crm[i][0]], r.y[crm[i][1]], r.z[crm[i][2]]], $fn=$fn*4);
				smooth_corner([r.x[crm[i][0]], r.y[crm[i][1]], r.z[crm[i][2]]], epsilon=epsilon, $fn=$fn*2);
			}
	
	//sides
//	frm=[[0], [0], [0], [0]];							// face rotation matrix, indexes for face polygon points
	translate(size/2){																													// to cube center
		//Z-
		for(a=[0:2]){
		if(a==2){
		rotate(a==0?[90, 0, 90]:a==1?[-90, -90, 0]:0) translate(-size/2)						// select and move to current axis
		linear_extrude(max(r.x[0], r.x[1], r.y[0], r.y[3]))
			polygon([
				[r.y[0],r.z[0]],
				max([r.y[0], r.x[0]])>r.z[0]?
					[r.y[0],r.x[0]]:
					[r.z[0],r.z[0]],
				[r.z[0],r.x[0]],
				
				[size.x-r.z[1],r.x[0]],
				max(r.y[3],r.x[0])>r.z[1]?
					[size.x-r.y[3],r.x[0]]:
					[size.x-r.z[1],r.z[1]],
				[size.x-r.y[3],r.z[1]],
				
				[size.x-r.y[3],size.y-r.z[2]],
				max(r.y[3],r.x[1])>r.z[2]?
					[size.x-r.y[3],size.y-r.x[1]]:
					[size.x-r.z[2],size.y-r.z[2]],
				[size.x-r.z[2],size.y-r.x[1]],
				
				[r.z[3],size.y-r.x[1]],
				max(r.y[0],r.x[1])>r.z[3]?
					[r.y[0],size.y-r.x[1]]:
					[r.z[3],size.y-r.z[3]],
				[r.y[0],size.y-r.z[3]]
			]);
			
		//Z+
		rotate(a==0?[90, 0, 90]:a==1?[-90, -90, 0]:0)
		translate([-size.x/2, -size.y/2, size.z/2-max(r.x[2], r.x[3], r.y[1], r.y[2])])						// select and move to current axis
		linear_extrude(max(r.x[2], r.x[3], r.y[1], r.y[2]))
			polygon([
				[r.y[1],r.z[0]],
				max(r.y[1],r.x[3])>r.z[0]?
					[r.y[1],r.x[3]]:
					[r.z[0],r.z[0]],
				[r.z[0],r.x[3]],

				[size.x-r.z[1],r.x[3]],
				max(r.x[3],r.y[2])>r.z[1]?
					[size.x-r.y[2],r.x[3]]:
					[size.x-r.z[1],r.z[1]],
				[size.x-r.y[2],r.z[1]],
				
				[size.x-r.y[2],size.y-r.z[2]],
				max(r.y[2],r.x[2])>r.z[2]?
					[size.x-r.y[2],size.y-r.x[2]]:
					[size.x-r.z[2],size.y-r.z[2]],
				[size.x-r.z[2],size.y-r.x[2]],
				
				[r.z[3],size.y-r.x[2]],
				max(r.x[2],r.y[1])>r.z[3]?
					[r.y[1],size.y-r.x[2]]:
					[r.z[3],size.y-r.z[3]],
				[r.y[1],size.y-r.z[3]]
			]);
		}
		//Y-
		if(a==1){
		rotate(a==0?[90, 0, 90]:a==1?[-90, -90, 0]:0)
		translate(-[size[2], size[0], size[1]]/2)						// select and move to current axis
		linear_extrude(max(r.z[0], r.z[1], r.x[0], r.x[3]))
			polygon([
				[r.x[0],r.y[0]],  //y->x  // z->y //x->z
				max(r.x[0],r.z[0])>r.y[0]?
					[r.x[0],r.z[0]]:
					[r.y[0],r.y[0]],
				[r.y[0],r.z[0]],
				
				[size.z-r.y[1],r.z[0]],
				max(r.x[3],r.z[0])>r.y[1]?
					[size.z-r.x[3],r.z[0]]:
					[size.z-r.y[1],r.y[1]],
				[size.z-r.x[3],r.y[1]],
				
				[size.z-r.x[3],size.x-r.y[2]],
				max(r.x[3],r.z[1])>r.y[2]?
					[size.z-r.x[3],size.x-r.z[1]]:
					[size.z-r.y[2],size.x-r.y[2]],
				[size.z-r.y[2],size.x-r.z[1]],
				
				[r.y[3],size.x-r.z[1]],
				max(r.x[0],r.z[1])>r.y[3]?
					[r.x[0],size.x-r.z[1]]:
				[r.y[3],size.x-r.y[3]],
				[r.x[0],size.x-r.y[3]]
			]);
			
		//Y+
		rotate(a==0?[90, 0, 90]:a==1?[-90, -90, 0]:0)
		translate(-[size[2], size[0], -size[1]]/2-[0, 0, max(r.z[2], r.z[3], r.x[1], r.x[2])])						// select and move to current axis
		linear_extrude(max(r.z[2], r.z[3], r.x[1], r.x[2]))
			polygon([

				[r.x[1],r.y[0]],
				max(r.x[1],r.z[3])>r.y[0]?
					[r.x[1],r.z[3]]:
					[r.y[0],r.y[0]],
				[r.y[0],r.z[3]],
				
				[size.z-r.y[1],r.z[3]],
				max(r.x[2],r.z[3])>r.y[1]?
					[size.z-r.x[2],r.z[3]]:
					[size.z-r.y[1],r.y[1]],
				[size.z-r.x[2],r.y[1]],
				
				[size.z-r.x[2],size.x-r.y[2]],
				max(r.x[2],r.z[2])>r.y[2]?
					[size.z-r.x[2],size.x-r.z[2]]:
					[size.z-r.y[2],size.x-r.y[2]],
				[size.z-r.y[2],size.x-r.z[2]],
				
				[r.y[3],size.x-r.z[2]],
				max(r.x[1],r.z[2])>r.y[3]?
					[r.x[1],size.x-r.z[2]]:
					[r.y[3],size.x-r.y[3]],
				[r.x[1],size.x-r.y[3]]
			]);
		}


		//X-
		if(a==0){
		rotate(a==0?[90, 0, 90]:a==1?[-90, -90, 0]:0)
		translate(-[size[1], size[2], size[0]]/2)						// select and move to current axis
		linear_extrude(max(r.y[0], r.y[1], r.z[0], r.z[3]))  //z->y  //x->z
			polygon([
				[r.z[0],r.x[0]],  //x->z  //y->x  //z->y?  (translating from y-axis to x-axis)
				max(r.z[0],r.y[0])>r.x[0]?
					[r.z[0],r.y[0]]:
					[r.x[0],r.x[0]],
				[r.x[0],r.y[0]],
				
				[size.y-r.x[1],r.y[0]],
				max(r.z[3],r.y[0])>r.x[1]?
					[size.y-r.z[3],r.y[0]]:
					[size.y-r.x[1],r.x[1]],
				[size.y-r.z[3],r.x[1]],
				
				[size.y-r.z[3],size.z-r.x[2]],
				max(r.z[3],r.y[1])>r.x[2]?
					[size.y-r.z[3],size.z-r.y[1]]:
					[size.y-r.x[2],size.z-r.x[2]],
				[size.y-r.x[2],size.z-r.y[1]],
				
				[r.x[3],size.z-r.y[1]],
				max(r.z[0],r.y[1])>r.x[3]?
					[r.z[0],size.z-r.y[1]]:
				[r.x[3],size.z-r.x[3]],
				[r.z[0],size.z-r.x[3]]
			]);
			
		//X+
		rotate(a==0?[90, 0, 90]:a==1?[-90, -90, 0]:0)
		translate(-[size[1], size[2], -size[0]]/2-[0, 0, max(r.y[2], r.y[3], r.z[1], r.z[2])])						// select and move to current axis
		linear_extrude(max(r.y[2], r.y[3], r.z[1], r.z[2]))
			polygon([

				[r.z[1],r.x[0]],
				max(r.z[1],r.y[3])>r.x[0]?
					[r.z[1],r.y[3]]:
					[r.x[0],r.x[0]],
				[r.x[0],r.y[3]],
				
				[size.y-r.x[1],r.y[3]],
				max(r.z[2],r.y[3])>r.x[1]?
					[size.y-r.z[2],r.y[3]]:
					[size.y-r.x[1],r.x[1]],
				[size.y-r.z[2],r.x[1]],
				
				[size.y-r.z[2],size.z-r.x[2]],
				max(r.z[2],r.y[2])>r.x[2]?
					[size.y-r.z[2],size.z-r.y[2]]:
					[size.y-r.x[2],size.z-r.x[2]],
				[size.y-r.x[2],size.z-r.y[2]],
				
				[r.x[3],size.z-r.y[2]],
				max(r.z[1],r.y[2])>r.x[3]?
					[r.z[1],size.z-r.y[2]]:
					[r.x[3],size.z-r.x[3]],
				[r.z[1],size.z-r.x[3]]
			]);
		}


		}
	}
	//fill center
	
	//debug fill
//	echo(r=r);
//	echo(size=size);
	translate([max(r.y[0], r.z[0]), max(r.x[0], r.z[0]), max(r.x[0], r.y[0])])
		cube(size-[max(r.y[0], r.z[0]), max(r.x[0], r.z[0]), max(r.x[0], r.y[0])]-[max(r.y[2], r.z[2]), max(r.x[2], r.z[2]), max(r.x[2], r.y[2])]);
}

*intersectcube(r=r, $fn=10);
module intersectcube(size=[10, 10, 10], r=[[1, 1, 1, 1], [1, 1, 1, 1], [1, 1, 1, 1]]){
	intersection(){
		//X
		rotate([90, 0, 90])
		side(size, r[0]);
		
		//Y
		rotate([-90, -90, 0])
		side(size, r[1]);
		
		//Z
		side(size, r[2]);
	}
}

*intersectcorner($fn=10);
module intersectcorner(r=[1, 1, 1], $fn=10){
	intersection(){
		//X
		translate([max(r), 0, 0])
			rotate([0, -90, 0])
				edge(max(r), r.x);
		
		//Y
		translate([0, max(r), 0])
			rotate([90, 0, 0])
				edge(max(r), r.y);
			
		//Z
		edge(max(r), r.z);
		
		//Bulk
		cube([max(r.y, r.z), max(r.x, r.z), max(r.x, r.y)]);
	}
}

*edge();
module edge(size=[1, 1, 10], r=1, $fn=10){
	size=is_list(size)?size:[r, r, size]; //if not a list make it a list
	linear_extrude(size.z)
		polygon([
			[size.x, 0],
			[size.x, size.y],
			[0, size.y],
			for(a=[0:90/$fn:90])
				[r-cos(a)*r, r-sin(a)*r]
		]);
}

*side();
module side(size=[10, 10, 10], r=[1, 2, 3, 4], full=true, $fn=10){
	linear_extrude(size.z)
		polygon([
			for(a=[0:90/$fn:90])
				[r[0]-cos(a)*r[0], r[0]-sin(a)*r[0]],
			for(a=[90:90/$fn:180])
				[size.x-r[1]-cos(a)*r[1], r[1]-sin(a)*r[1]],
			for(a=[180:90/$fn:270])
				[size.x-r[2]-cos(a)*r[2], size.y-r[2]-sin(a)*r[2]],
			for(a=[270:90/$fn:360])
				[r[3]-cos(a)*r[3], size.y-r[3]-sin(a)*r[3]],
		]);
}

// super simplified version using hull() - not accurate
*hull_roundedcorner(r=[1, 3, 5], $fn=100);
module hull_roundedcorner(r=[1, 4, 3]){ // n=10, a1=90, a2=90, epsilon=0.01
	intersection(){
		cube(max(r));
		hull(){
			translate([max(r), r.x, r.x])
				sphere(r.x);
			translate([r.y, max(r), r.y])
				sphere(r.y);
			translate([r.z, r.z, max(r)])
				sphere(r.z);
		}
	}
}

// simplified version using rotate_extrude() - not accurate but slightly prettier
*roundedcorner(r=[1, 3, 5], $fn=50);
module roundedcorner(r=[4, 2, 1], epsilon=0.01){
//	union(){
	hull(){
		for(axis=[0:2])
			let(
				is_min=r[axis]<=min(r[(axis+1)%3], r[(axis+2)%3])?true:false,
				min_buddy=r[(axis+1)%3]<r[(axis+2)%3]?1:2,
				r_buddy=r[(axis+min_buddy)%3],
				join_r=max(r)-r_buddy
			){
			//echo(axis=axis,min_buddy=str("+",min_buddy),is_min=is_min,r=r[axis],join_r=join_r)
			color(axis==0?"red":axis==1?"green":"blue")
				rotate(axis==0?[90, 0, 90]:axis==1?[-90, -90, 0]:0)													// select current axis
					translate([r[axis], r[axis], max(r)-r[axis]]+
										(is_min?[
											min_buddy==1?join_r		:0*max(r)-r[axis],
											min_buddy==1?-r[axis]	:join_r,
											min_buddy==1?r[axis]	:(r[axis]-r[(axis+1)%3])+max(r),
										]:[0, 0, 0]))
						rotate(is_min?min_buddy==1?[0, 90, 90]:[-90, 0, -90]:[0, 0, 180])
							rotate_extrude(angle=90)
								translate([is_min?join_r:0, 0])
									if(!(is_min&&r[axis]==r_buddy&&min_buddy==2)||(r[0]==r[1]&&r[1]==r[2]&&axis==0))
										if(r[axis]!=0)
											polygon([
												for(a=[0:90/$fn*4:90])
													[sin(a)*r[axis], (1-cos(a))*r[axis]],
												[r[axis], r[axis]],
												[0, r[axis]]
											]);
										else
											translate([-epsilon, 0])
												square(epsilon);
			}
	}
}

//prototype for alternative rotate_extrude() exposing $angle as iterator variable
module alt_rotate_extrude(angle=360, convexity=2){
	$fn=($fn==undef||$fn==0)?10:$fn;
	echo($fn, angle)
	for(angle=[0:360/$fn:angle]){
		rotate([0, 0, angle])
			rotate_extrude(angle=360/$fn, convexity = convexity)
				children($angle=angle);
	}
}

// snail shell (approximated seashell surface)
*snail_shell();
module snail_shell(){
	let(phi=(sqrt(5)+1)/2)
		alt_rotate_extrude(angle=900, convexity=2, $fn=50)
			let(v=pow(phi,$angle/200))
			translate([v, 2.2*v])
			difference(){
				circle(r=v, $fn=$fn);
				circle(r=v*0.9, $fn=$fn);
			}
}

function magic(a)=cos_lim(a);
function magic2(a)=1-cos(lim(90*(a/90)^1.5, 0, 90)*2)/2-.5;
function cos_stretch(a)=(0.5-cos(180-(lim((1-a/90)^1.2, 0, 1)*2)*90)/2);
function cos_lim(a)=1-cos(lim(a, 0, 90));										// Works best together with intersection_for()
function sqr_lim(a)=(lim(a, 0, 90)/90)^2;										// almost similar to cos_lim()
function smooth_inv(a)=(2*a+(cos(2*a))/2)-.5;								// inverted
function smooth_lim(a)=(1-cos(2*lim(a, 0, 90)))/2;					// truncated
function smooth(a)=(1-cos(2*lim(a, 0, 90)))/2;													// original, very close to the ideal
function smooth0(a)=(1-cos(lim(a, 0, 90)));
function smooth1(a)=sin(lim(a, 0, 90));
function sinbell(a)=sin(2*lim(a, 0, 90));
function cosbell(a)=(-cos(4*lim(a, 0, 90))+1)/2;
function lim(a, lo, hi)=min(max(a, lo), hi);
function mix(v1, v2, rate, thr0=0, thr1=1)=lookup(rate, [[-1, v1], [thr0, v1], [thr1, v2], [2, v2]]);
function mix_old(v1, v2, rate)=v1*rate+v2*(1-rate);
function offset(v1, v2, rate)=abs(v1-v2)*(v1<v2?1-rate:rate);
function quicksort(list="") = !(len(list)>0) ? [] : let(
    pivot   = list[floor(len(list)/2)],
    lesser  = [ for (i = list) if (i  < pivot) i ],
    equal   = [ for (i = list) if (i == pivot) i ],
    greater = [ for (i = list) if (i  > pivot) i ]
) concat(
    quicksort(lesser), equal, quicksort(greater)
);


/* WIP begin */
// Idea for optimal rounded corners algorith that ultimately relies upon the principle of alt_rotate_extrude()
*optimalroundcorner();
// (r.x*mix+r.y*(1-i1))
// mix(r.x,r.y,i1)
module optimalroundcorner(r=[8, 10, 5], n=10, a1=90, a2=90, epsilon=0.01){
	hcut=((0<a2&&a2<90)?tan(a2)*(1-sin(a2))*r.x:0);
	xydif=abs(r.x-r.y);
	xyzdif=max(r)-min(r);
//	translate(-[1, 1, 1]*max(r))
//	rotate_extrude(angle=a1, $fn=4*n)
	for(i1=[0:1/n:1])
	rotate([0, 0, i1*a1-a1/(2*n)])
	rotate_extrude(angle=a1/n, $fn=1)
	
		polygon([
			[0, 0],
			[(r.x<0?0:max(r)), 0],
			for(i2=[0:1/n:1])
				[(r.x<0?-mix(r.x,r.y,i1):0)+cos(i2*a2)*mix(r.x,r.y,i1)+xyzdif-offset(r.x,r.y,i1), sin(i2*a2)*abs(mix(r.x,r.y,i1))+offset(r.y,r.x,i1)],
			[(r.x<0?-mix(r.x,r.y,i1):0)-(1-cos(a2))*mix(r.x,r.y,i1)+mix(r.x,r.y,i1)-hcut,									 abs(mix(r.x,r.y,i1))+offset(r.y,r.x,i1)],
			[(r.x<0?-mix(r.x,r.y,i1):0)-(1-cos(a2))*mix(r.x,r.y,i1)+mix(r.x,r.y,i1)-hcut,									 abs(mix(r.x,r.y,i1))+(r.x<0?epsilon:0)],
			[0, abs(r.x)+(r.x<0?epsilon:0)]
		]);
}
/* WIP end */

// Alternate experimental rotate_extrude using intersection_for() that comes very close to the optimal topology
// This tecnique has its drawbacks, for instance aligning polygons to surrounding edges is not straight forward
*intersection_for_corner();
module intersection_for_corner(){
	let(r=[1, 3, 5], max_r=r[2], max_r12=max(r[0], r[1]), dif_r=r[2]-r[1], epsilon=0.10, $fn=50){
		intersection(){
			translate(max_r*[1, 1, 0])
			intersection_for(a=[(-180/$fn):360/$fn:90+180/$fn], convexity=10){
				let(ri=mix(r[0], r[1], cos_lim(90-a)), pos=r[2]-(r[2]-ri))
				rotate([0, 0, lim(a, 0, 90)])
				rotate([90, 0, 0])
				translate([epsilon, 0, 0])
				linear_extrude(height = 3*max_r, center=true, convexity=10){
					translate([-epsilon+ri-max_r, ri])
					circle(r=ri, $fn=$fn);
					translate([-epsilon+ri-max_r, 0])
					square([epsilon+max_r-ri, 2*max_r]);
					translate([-epsilon-max_r, ri])
					square([epsilon+max_r, 2*max_r-ri]);
				}
			}
			translate([-epsilon, -epsilon, -epsilon])
			cube([1, 1, 1]*2*epsilon+[1, 1, 1]*max_r);
		}
		union(){
			// X
			translate([max_r, r[0], r[0]])
			rotate([90, 0, 90])
			cylinder(r=r[0], h=max_r);

			// Y
			translate([r[1], max_r, r[1]])
			rotate([-90, 0, 0])
			cylinder(r=r[1], h=max_r);

			// Z
			translate([r[2], r[2], max_r])
			rotate([0, 0, 0])
			cylinder(r=r[2], h=max_r, $fn=$fn);
		}
	}
}


function pointer_sort(r)=
	r[0]<r[1]?
	r[1]<r[2]?[0, 1, 2]:	// [1, 2, 3]
	r[2]<r[0]?[2, 0, 1]:	// [2, 3, 1]
						[0, 2, 1]:	// [1, 3, 2]
	r[2]<r[1]?[2, 1, 0]:	// [3, 2, 1]
	r[0]<r[2]?[1, 0, 2]:	// [2, 1, 3]
						[1, 2, 0];	// [3, 1, 2]

*test_pointer_sort();
module test_pointer_sort(){
	for(x=[1:5], y=[1:5], z=[1:5])
		let(size=[x, y, z])
		translate(6*size)
			let(p=pointer_sort(size))
				for(n=[0:2])
					translate([n, 0, 0])
						color(p[n]==0?"red":p[n]==1?"green":"blue")
							cube([1, 1, size[p[n]]]);
}

// mirrors and rotates around origin so that the smallest parameter ends up along the x-axis
// and the biggest parameter along the z-axis
module mirrotate(r){
	mirror(
		r[0]<r[1]?
		r[1]<r[2]?[0, 0, 0]:		// 
		r[2]<r[0]?[0, 0, 0]:		// 
							[0, 1, 0]:		// 
		r[2]<r[1]?[1, 0, 0]:		// 
		r[0]<r[2]?[1, 0, 0]:		// 
							[0, 0, 0]			// 
	)
	rotate(
		r[0]<r[1]?
		r[1]<r[2]?[0,  0,	 0]:	// 012
		r[2]<r[0]?[0,-90,-90]:	// 201
							[90, 0,	 0]:	// 021
		r[2]<r[1]?[0,-90,	 0]:	// 210
		r[0]<r[2]?[0,  0,	90]:	// 102
							[90, 0,	90]		// 120
	)
	children();
*	echo(mirrotate=
		r[0]<r[1]?
		r[1]<r[2]?[0, 1, 2]:	// 012
		r[2]<r[0]?[2, 0, 1]:	// 201
							[0, 2, 1]:	// 021
		r[2]<r[1]?[2, 1, 0]:	// 210
		r[0]<r[2]?[1, 0, 2]:	// 102
							[1, 2, 0]		// 120
	);
}

//$vpt=[3, 3, 0];
//$vpr=[0, 0, 0];
//$vpd=25;
// Visualize and sort the three edge/corner parameters (r.x <= r.y <= r.z)
// Color according to original axis
*origins(r=[3, 5, 1], $fn=50);
module origins(r=[1, 3, 5], $fn=50)
let(p=pointer_sort(r), rs=[r[p[0]], r[p[1]], r[p[2]]]){
	mirrotate(r)
	{
		color(p[0]==0?"red":p[0]==1?"green":"blue")
			translate([rs[2], rs[0], abs(rs[0])])
				rotate([0, 90, 0])
					cylinder(r=rs[0]!=0?abs(rs[0]):0.001, h=abs(rs[2]));
		color(p[1]==0?"red":p[1]==1?"green":"blue")
			translate([rs[1], rs[2], abs(rs[1])])
				rotate([-90, 0, 0])
					cylinder(r=rs[1]!=0?abs(rs[1]):0.001, h=abs(rs[2]));
		color(p[2]==0?"red":p[2]==1?"green":"blue")
			translate([rs[2], rs[2], max(abs(rs[0]), abs(rs[1]))])
				rotate([0, 0, 0])
					cylinder(r=rs[2]!=0?abs(rs[2]):0.001, h=abs(rs[2]));
		
		color("black")
			translate([rs[2], rs[2], 0])
				cylinder(r=.1, h=abs(rs[2]));
	}
}

*for(x=[0:90]) plotxy(x/90, cosbell(x));
// cartesian graph plotting
module plotxy(x, y, c="black"){
	color(c)
	translate([x, y, 0])
	cylinder(d=0.05, h=0.05, $fn=8);
}
module plotyz(y, z, c="black"){
	color(c)
	translate([0, y, z])
	cylinder(d=0.05, h=0.05, $fn=8);
}

// polar graph plotting
module plotpol(a, r, c="black"){
	color(c)
	rotate(a)
	translate([r, 0, 0])
	cylinder(d=0.05, h=0.05, $fn=8);
}

// locate a coordinate
module find(lok){
	translate(lok)
		rotate([180, 90, 45])
			color("violet")
				cylinder(r1=0, r2=0.1, h=1);
}

// optimal topology rounded corner
*smooth_corner(r=[2, 2, 4], epsilon=0, $fn=31);
module smooth_corner(r=[1, 3.44406, 5], epsilon=0, $fn=100){
	p							= pointer_sort(r);
	rs						= [r[p[0]], r[p[1]], r[p[2]]];
	dist					= rs[2]-rs[1];
	dist2					= rs[1]-rs[0];
	rdist					= PI*dist/2;
	a_trans				= atan2(-dist, dist2);
	bend_len			= (rdist+dist2==0)?1:rdist/(rdist+dist2);
	straight_len	= (rdist+dist2==0)?0:dist2/(rdist+dist2);
	rmaxabs				= max(abs(rs[0]), abs(rs[1]));
	inverted			= min(rs)<0?true:false;
	mirrotate(r)
	union(){
		
		// build list of 3D points
		points=[
			for(v = [0 : 1/$fn : 1])
				let(a  = (v<=bend_len)? (v!=0)? v/bend_len : 0: (v-bend_len)/straight_len,	// a = segmented iterator value
						x1 = (v<=bend_len)? dist*sin(90*a)				: dist,												// x1 & y1 = trace points
						y1 = (v<=bend_len)? dist*cos(90*a)+dist2	: (1-a)*dist2,
						x2 = x1-rs[2]*sin(90*v),																								// x2 & y2 = horizontal distance from trace to peripheral points
						y2 = y1-rs[2]*cos(90*v),
						ra = atan2(y2, x2),																											// ra = Z-axis rotation
						rf = sqrt(y2^2+x2^2),																										// rounding radius from trace towards periphery
						vt=[cos(ra), sin(ra)] )																									// angle from trace towards periphery
					each[
						[rf*vt.x-x1, rf*vt.y-y1, rmaxabs+epsilon],															// peripheral rounding point
						for(a=[0:90/$fn:90])																										// bending
							let(d=(cos(a))*rf)
								[d*vt.x-x1, d*vt.y-y1, (1-sin(a))*abs(rf)],
						[-x1, -y1, inverted?-epsilon:0] ],																			// rounding lower part
					[0, 0, rmaxabs+epsilon],																									// upper corner: len(points)-2
					[0, 0, inverted?-epsilon:0]																								// lower corner: len(points)-1
			];
		
		// build list of faces
		let(n=$fn+3,
				m=$fn+1){
			faces=[
				for(i=[0:$fn-1], j=[0:$fn+1])																								// curved surface
				 		[i*n+j+1, (i+1)*n+j+1, (i+1)*n+j, i*n+j],
				[for(i=[$fn+2 : -1 : 0]) i, len(points)-2, len(points)-1],									// X surface
				[for(i=[n*m-n : 1 : n*m-1]) i, len(points)-1, len(points)-2],								// Y surface
				[for(i=[n*(m-n+2) : n : n*(m-n+2+$fn)]) i, len(points)-2],									// Z upper surface
				[for(i=[n*(m-n+3+$fn)-1 : -n : n*(m-n+3)-1]) i, len(points)-1]							// Z lower surface
			];
			
			// render
			translate(rs[2]*[1, 1, 0])
				polyhedron(points, faces);
			
			*translate(rs[2]*[1, 1, 0])
				find(points[(($fn+1)-5)*(($fn+3))-9]);
		}
		*origins(r=rs, $fn=$fn*4);
	}
}

*origin0();
module origin0(r=[1.8, 3, 1], $fn=98){
*	union(){
		translate([r.z, r.z, max(r)+.01]){
			color("blue")
				cylinder(r=r.z, h=max(r));
	*		rotate([180, 0, 0])
	%				cylinder(r=r.z, h=max(r));
			}
		translate([r.y, max(r)+.01, r.y])
			rotate([-90, 0, 0]){
				color("green")
					cylinder(r=r.y, h=max(r));
	*			rotate([180, 0, 0])
	%				cylinder(r=r.y, h=max(r));
			}
		translate([max(r)+.01, r.x, r.x])
			rotate([90, 0, 90]){
				color("red")
					cylinder(r=r.x, h=max(r));
	*			rotate([0, 180, 0])
	%				cylinder(r=r.x, h=max(r));
			}
	}
//	hull()
	intersection(){
		cube(max(r)*[1, 1, 1]);
		union(){
			color("green")
				translate([r.y, max(r)-.01, r.y])
					rotate([-90, 0, 0])
						cylinder(r=r.y, h=.01);
			color("red")
				translate([max(r)-.01, r.x, r.x])
					rotate([90, 0, 90])
						cylinder(r=r.x, h=.01);
			color("red")
				translate([max(r)-.01, 0, r.x])
					cube([.01, r.x, r.x+r.y-r.x]);
*			translate(max(r)*[1, 1, 1])
				sphere(max(r));

			color("blue")
			for(v=[0:90/($fn/4):90])
//				let(dz=[mix(r.z, r.y, v/90), mix(r.z, r.x, v/90), max(r)-max(r)*0*sinbell(v)/2])
				let(d=mix(r.z, 0, smooth0(90*sqeeze(v/90, thr0=asin((r.y-r.x)/r.y)/90))))
				let(rz=mix(r.z, max(r), v/90)){
					translate([max(r)+d-mix(0, r.y, cos(v)), d+mix(r.x, 0, cos(90*sqeeze(v/90, thr0=asin((r.y-r.x)/r.y)/90))), max(r)-sin(v)*max(r)])
						rotate([0, 0, 180])
							intersection(){
								cylinder(r=d+0.001, h=0.01, center=true);
								translate([0, 0, -1])
									cube([d<=0?0.001:2*d, d<=0?0.001:2*d, 2]);
							}
				}
		}
	}
*for(v=[0:90/($fn/4):90])
//	let(d=mix(r.z, 0, (90*sqeeze(v/90, thr0=0.21))/90))
	let(d=mix(r.z, 0, smooth0(90*sqeeze(v/90, thr0=asin((r.y-r.x)/r.y)/90))))
	let(rz=mix(r.z, max(r), v/90)){
		plotyz(mix(r.x, 0, cos(90*sqeeze(v/90, thr0=asin((r.y-r.x)/r.y)/90))), max(r)-sin(v)*max(r), "yellow");
		plotyz(-d, max(r)-sin(v)*max(r), "red");
	}

*echo(asin((r.y-r.x)/r.y)/90);
//echo(1-cos(90*r.x/r.y));
}

function sqeeze(in, thr0=0, thr1=1)=lim((in-thr0)/(thr1-thr0), 0, 1);


*for(v=[0:90])
	plotyz(-v/90, sqeeze(v/90, thr0=0.2, thr1=.9));

*origin1($fn=50);
module origin1(r=[3, .1]){
	union(){
//	difference(){
//		translate([r.x, r.x])
//			circle(r.x);
	translate([r.x, r.x])
		for(v=[0:1:33])
			let(d=mix(r.y, r.x, smooth0(v)))
			translate([-cos(v)*(r.x-d), -sin(v)*(r.x-d)])
//				circle(d);
				sphere(d);
	}
}
