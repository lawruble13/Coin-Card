h = 3.3000000000000003;
hbp = 0.3;
W = 86.0;
H = 54.0;
B = 0.10000002986498693;
CR = 2.5;
difference(){
    translate(v=[-B, -B, 0]){
        cube([W+2*B, H+2*B, h+hbp]);
    };
    translate(v=[48.1432766072475,12.838731004879353,0]){
        translate(v=[0,0,hbp+h-1.65]) cylinder(h=h*1.1,r=10.6+0.2);
        translate(v=[0,0,-0.05*hbp]) cylinder(h=1.1*hbp+h,r=(10.6+0.2)/2);
    };
    translate(v=[13.176162863571141,12.83873099426297,0]){
        translate(v=[0,0,hbp+h-2.3]) cylinder(h=h*1.1,r=9.0+0.2);
        translate(v=[0,0,-0.05*hbp]) cylinder(h=1.1*hbp+h,r=(9.0+0.2)/2);
    };
    translate(v=[29.799482884531905,19.742731886778714,0]){
        translate(v=[0,0,hbp+h-2.3]) cylinder(h=h*1.1,r=9.0+0.2);
        translate(v=[0,0,-0.05*hbp]) cylinder(h=1.1*hbp+h,r=(9.0+0.2)/2);
    };
    translate(v=[70.69327649887202,12.838730995593806,0]){
        translate(v=[0,0,hbp+h-3.0]) cylinder(h=h*1.1,r=11.95+0.2);
        translate(v=[0,0,-0.05*hbp]) cylinder(h=1.1*hbp+h,r=(11.95+0.2)/2);
    };
    translate(v=[14.543068036682161,36.85179647178384,0]){
        translate(v=[0,0,hbp+h-1.85]) cylinder(h=h*1.1,r=13.3+0.2);
        translate(v=[0,0,-0.05*hbp]) cylinder(h=1.1*hbp+h,r=(13.3+0.2)/2);
    };
    translate(v=[42.69327663153301,38.788730880545266,0]){
        translate(v=[0,0,hbp+h-1.7]) cylinder(h=h*1.1,r=14.0+0.2);
        translate(v=[0,0,-0.05*hbp]) cylinder(h=1.1*hbp+h,r=(14.0+0.2)/2);
    };
    translate(v=[70.69327649739688,38.78873087261294,0]){
        translate(v=[0,0,hbp+h-1.7]) cylinder(h=h*1.1,r=14.0+0.2);
        translate(v=[0,0,-0.05*hbp]) cylinder(h=1.1*hbp+h,r=(14.0+0.2)/2);
    };
    difference(){
        translate(v=[-B-0.01,-B-0.01,-h*0.1]){
            cube([CR, CR, h*1.2+hbp]);
        };
        translate(v=[-B+CR,-B+CR,-h*0.1]){
            cylinder(h=h*1.2+hbp, r=CR);
        };
    };
    difference(){
        translate(v=[W+B-CR+0.01,-B-0.01,-h*0.1]){
            cube([CR, CR, h*1.2+hbp]);
        };
        translate(v=[W+B-CR,-B+CR,-h*0.1]){
            cylinder(h=h*1.2+hbp, r=CR);
        };
    };
    difference(){
        translate(v=[-B-0.01,H+B-CR+0.01,-h*0.1]){
            cube([CR, CR, h*1.2+hbp]);
        };
        translate(v=[-B+CR,H+B-CR,-h*0.1]){
            cylinder(h=h*1.2+hbp, r=CR);
        };
    };
    difference(){
        translate(v=[W+B-CR+0.01,H+B-CR+0.01,-h*0.1]){
            cube([CR, CR, h*1.2+hbp]);
        };
        translate(v=[W+B-CR,H+B-CR,-h*0.1]){
            cylinder(h=h*1.2+hbp, r=CR);
        };
    };
};