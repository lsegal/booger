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
