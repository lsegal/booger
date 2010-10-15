# @requires x >= 0
# @ensures $result == x + y - 2
# @param [Fixnum] x
# @param [Fixnum] y
# @return [Fixnum]
def inc(x, y)
  return x + y
end

# @ensures $result == x * x * x
def cube(x)
  return x * x
end

__END__

$ ./bin/booger examples/example1.rb 
Verification Errors (4):

- A postcondition might not hold at this return statement:4:
      x + y

- This is the postcondition that might not hold:
      @ensure $result == x + y - 2

- A postcondition might not hold at this return statement:9:
      x * x

- This is the postcondition that might not hold:
      @ensure $result == x * x * x
