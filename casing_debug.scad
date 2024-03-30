
/*
//test();
test(a=2);

module test(a){
	$a = !is_undef(a)?a:1;
	test2();
}

module test2(){
	echo($a);
}
*/

/*

function toUpper(inputStr) = [for (c = inputStr) chr((ord(c) >= ord("a") && ord(c) <= ord("z"))?(ord(c) - ord("a") + ord("A")):ord(c))];
function join(v,i) = i>1?str(v[len(v)-i], join(v,i-1)):v[len(v)-i];
function ucase(s) = let(u=toUpper(s))	join(u, len(s));
echo(ucase("Hello, World!")); // Output: "HELLO, WORLD!"
*/



function toUpper(inputStr) = [for (c = inputStr) chr((ord(c) >= ord("a") && ord(c) <= ord("z"))?(ord(c) - ord("a") + ord("A")):ord(c))];
function join(v,i) = i>1?str(v[len(v)-i], join(v,i-1)):v[len(v)-i];
function ucase(s) = let(u=toUpper(s))	join(u, len(s));
echo(ucase("Hello, World!")); // Output: "HELLO, WORLD!"
