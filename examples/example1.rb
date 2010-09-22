# @requires x >= 0
# @ensures __result__ == x + y - 2
def inc(x, y)
  return x + y
end

# @ensures __result__ == x * x * x
def cube(x)
  return x * x
end

__END__

$ ./bin/booger examples/example1.rb 
Verification Errors (4):

- A postcondition might not hold at this return statement:4:
      x + y

- This is the postcondition that might not hold:
      @ensure __result__ == x + y - 2

- A postcondition might not hold at this return statement:9:
      x * x

- This is the postcondition that might not hold:
      @ensure __result__ == x * x * x
