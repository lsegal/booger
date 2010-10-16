class Stack
  # @modifies @elements
  # @modifies @size
  def initialize
    @size = 0
  end
  
  # @modifies @elements
  # @modifies @size
  # @ensures @size == old(@size) + 1
  def push(element)
    @size = @size + 1
    @elements.push element
  end
  
  # @modifies @size
  # @requires @size > 0
  # @ensures @size == old(@size) - 1
  def pop
    @size = @size - 1
    @elements.pop
  end
end

# @modifies "Stack@size"
# @modifies "Stack@elements"
def use
  stack = Stack.new
  stack.pop
end

__END__

booger (master)$ RESULTS=1 ./bin/booger examples/example3.rb 
====== Boogie Output (boogie20101015-3556-3bc5t6.bpl) (0.07s) ======

type VALUE = int;
const BasicObject: VALUE;
const Object: VALUE;
const Stack: VALUE;
axiom Object <: Object;
axiom Stack <: Object;
var Stack$size: [VALUE]VALUE;
var Stack$elements: [VALUE]VALUE;

procedure Stack#initialize(self: VALUE) returns ($result: VALUE) modifies Stack$elements; modifies Stack$size; {
  Stack$size[self] := 0;
  return;
}

procedure Stack#push(self: VALUE, element: VALUE) returns ($result: VALUE) ensures Stack$size[self] == old(Stack$size[self]) + 1; modifies Stack$elements; modifies Stack$size; {
  Stack$size[self] := Stack$size[self] + 1;
  return;
}

procedure Stack#pop(self: VALUE) returns ($result: VALUE) requires Stack$size[self] > 0; ensures Stack$size[self] == old(Stack$size[self]) - 1; modifies Stack$size; {
  Stack$size[self] := Stack$size[self] - 1;
  return;
}

procedure #use(self: VALUE) returns ($result: VALUE) modifies Stack$size; modifies Stack$elements; {
  var stack: VALUE;
  var unused: VALUE;
  call unused := Stack#initialize(stack);
  call unused := Stack#pop(stack);
  return;
}

>> Running: `boogie /nologo boogie20101015-3556-3bc5t6.bpl'...

====== Boogie Results (1.54s) ======

boogie20101015-3556-3bc5t6.bpl(29,3): Error BP5002: A precondition for this call might not hold.
boogie20101015-3556-3bc5t6.bpl(20,59): Related location: This is the precondition that might not hold.
Execution trace:
        boogie20101015-3556-3bc5t6.bpl(28,3): anon0

Boogie program verifier finished with 3 verified, 1 error

====== Results ======

Verification Errors (2):

- A precondition for this call might not hold:29:
      stack.pop

- This is the precondition that might not hold:
      @requires @size > 0

