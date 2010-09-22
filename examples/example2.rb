# @ensures __result__ == 9
def if_then
  x = 10
  if x == 2
    x = 5
  else
    x = 9
  end
  return x
end

__END__

$ RESULTS=true ./bin/booger examples/example2.rb 
====== Boogie Output (boogie20100922-2856-apw8yw.bpl) (0.07s) ======

procedure #if_then() returns (__result__ : int) ensures __result__ == 9; {
  var x: int;
  x := 10;
  if (x == 2) {
    x := 5;
  }
  else {
    x := 9;
  }
  __result__ := x;
  return;
}

>> Running: `boogie /nologo boogie20100922-2856-apw8yw.bpl'...

====== Boogie Results (1.43s) ======


Boogie program verifier finished with 1 verified, 0 errors

====== Results ======

Success.
