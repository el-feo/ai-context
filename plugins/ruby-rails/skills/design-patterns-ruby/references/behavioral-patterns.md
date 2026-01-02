# Behavioral Patterns Reference

Detailed Ruby implementations for behavioral design patterns.

## Chain of Responsibility

**Intent**: Lets you pass requests along a chain of handlers. Upon receiving a request, each handler decides either to process the request or to pass it to the next handler in the chain.

**When to use**:
- Program must handle various requests whose types and sequences aren't predetermined
- Multiple handlers must execute in a specific order
- Handler chains need modification at runtime

```ruby
class Handler
  attr_writer :next_handler

  def next_handler=(handler)
    @next_handler = handler
    handler
  end

  def handle(request)
    return @next_handler.handle(request) if @next_handler

    nil
  end
end

class MonkeyHandler < Handler
  def handle(request)
    if request == 'Banana'
      "Monkey: I'll eat the #{request}"
    elsif @next_handler
      @next_handler.handle(request)
    end
  end
end

class SquirrelHandler < Handler
  def handle(request)
    if request == 'Nut'
      "Squirrel: I'll eat the #{request}"
    elsif @next_handler
      @next_handler.handle(request)
    end
  end
end

class DogHandler < Handler
  def handle(request)
    if request == 'MeatBall'
      "Dog: I'll eat the #{request}"
    elsif @next_handler
      @next_handler.handle(request)
    end
  end
end

# Client code
def client_code(handler)
  ['Nut', 'Banana', 'Cup of coffee'].each do |food|
    puts "\nClient: Who wants a #{food}?"
    result = handler.handle(food)
    if result
      print "  #{result}"
    else
      print "  #{food} was left untouched."
    end
  end
end

monkey = MonkeyHandler.new
squirrel = SquirrelHandler.new
dog = DogHandler.new

monkey.next_handler = squirrel
squirrel.next_handler = dog

puts 'Chain: Monkey > Squirrel > Dog'
client_code(monkey)
puts "\n\n"

puts 'Subchain: Squirrel > Dog'
client_code(squirrel)
```

**File**: `Ruby/src/chain_of_responsibility/conceptual/main.rb`

---

## Command

**Intent**: Turns a request into a stand-alone object that contains all information about the request. This transformation lets you pass requests as method arguments, delay or queue a request's execution, and support undoable operations.

**When to use**:
- Parameterizing objects with operations
- Queuing, scheduling, or remote execution of operations
- Implementing reversible operations (undo/redo)

```ruby
class Command
  def execute
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class SimpleCommand < Command
  def initialize(payload)
    @payload = payload
  end

  def execute
    puts "SimpleCommand: See, I can do simple things like printing (#{@payload})"
  end
end

class ComplexCommand < Command
  def initialize(receiver, a, b)
    @receiver = receiver
    @a = a
    @b = b
  end

  def execute
    print 'ComplexCommand: Complex stuff should be done by a receiver object'
    @receiver.do_something(@a)
    @receiver.do_something_else(@b)
  end
end

class Receiver
  def do_something(a)
    print "\nReceiver: Working on (#{a}.)"
  end

  def do_something_else(b)
    print "\nReceiver: Also working on (#{b}.)"
  end
end

class Invoker
  def on_start=(command)
    @on_start = command
  end

  def on_finish=(command)
    @on_finish = command
  end

  def do_something_important
    puts 'Invoker: Does anybody want something done before I begin?'
    @on_start.execute if @on_start.is_a? Command

    puts 'Invoker: ...doing something really important...'

    puts 'Invoker: Does anybody want something done after I finish?'
    @on_finish.execute if @on_finish.is_a? Command
  end
end

# Client code
invoker = Invoker.new
invoker.on_start = SimpleCommand.new('Say Hi!')
receiver = Receiver.new
invoker.on_finish = ComplexCommand.new(receiver, 'Send email', 'Save report')

invoker.do_something_important
```

**File**: `Ruby/src/command/conceptual/main.rb`

---

## Iterator

**Intent**: Lets you traverse elements of a collection without exposing its underlying representation (list, stack, tree, etc.).

**When to use**:
- Collection has intricate internal structure requiring simplified access
- Multiple algorithms for traversing collections create redundant code
- Code must handle various collection types or unknown future structures

**Ruby note**: Ruby's `Enumerable` module provides built-in iterator support via `each`.

```ruby
class AlphabeticalOrderIterator
  include Enumerable

  attr_accessor :reverse
  private :reverse

  attr_accessor :collection
  private :collection

  def initialize(collection, reverse: false)
    @collection = collection
    @reverse = reverse
  end

  def each(&block)
    return @collection.items.reverse.each(&block) if reverse

    @collection.items.each(&block)
  end
end

class WordsCollection
  attr_accessor :items

  def initialize(collection = [])
    @items = collection
  end

  def iterator
    AlphabeticalOrderIterator.new(self)
  end

  def reverse_iterator
    AlphabeticalOrderIterator.new(self, reverse: true)
  end
end

# Client code
collection = WordsCollection.new
collection.items << 'First'
collection.items << 'Second'
collection.items << 'Third'

puts 'Straight traversal:'
collection.iterator.each { |item| puts item }
puts "\n\n"

puts 'Reverse traversal:'
collection.reverse_iterator.each { |item| puts item }
```

**File**: `Ruby/src/iterator/conceptual/main.rb`

---

## Mediator

**Intent**: Lets you reduce chaotic dependencies between objects. The pattern restricts direct communications between the objects and forces them to collaborate only via a mediator object.

**When to use**:
- Classes are tightly coupled to many other classes
- Components cannot be reused because they depend on too many others
- Creating excessive component subclasses to reuse basic behavior

```ruby
class Mediator
  def notify(_sender, _event)
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class ConcreteMediator < Mediator
  def initialize(component1, component2)
    @component1 = component1
    @component1.mediator = self
    @component2 = component2
    @component2.mediator = self
  end

  def notify(_sender, event)
    if event == 'A'
      puts 'Mediator reacts on A and triggers following operations:'
      @component2.do_c
    elsif event == 'D'
      puts 'Mediator reacts on D and triggers following operations:'
      @component1.do_b
      @component2.do_c
    end
  end
end

class BaseComponent
  attr_accessor :mediator

  def initialize(mediator = nil)
    @mediator = mediator
  end
end

class Component1 < BaseComponent
  def do_a
    puts 'Component 1 does A.'
    @mediator.notify(self, 'A')
  end

  def do_b
    puts 'Component 1 does B.'
    @mediator.notify(self, 'B')
  end
end

class Component2 < BaseComponent
  def do_c
    puts 'Component 2 does C.'
    @mediator.notify(self, 'C')
  end

  def do_d
    puts 'Component 2 does D.'
    @mediator.notify(self, 'D')
  end
end

# Client code
c1 = Component1.new
c2 = Component2.new
ConcreteMediator.new(c1, c2)

puts 'Client triggers operation A.'
c1.do_a

puts "\n"

puts 'Client triggers operation D.'
c2.do_d
```

**File**: `Ruby/src/mediator/conceptual/main.rb`

---

## Memento

**Intent**: Lets you save and restore the previous state of an object without revealing the details of its implementation.

**When to use**:
- Need snapshots of object state to restore previous states (undo/redo, transactions)
- Direct access to object fields/getters/setters violates encapsulation

```ruby
class Originator
  attr_accessor :state
  private :state

  def initialize(state)
    @state = state
    puts "Originator: My initial state is: #{@state}"
  end

  def do_something
    puts 'Originator: I\'m doing something important.'
    @state = generate_random_string(30)
    puts "Originator: and my state has changed to: #{@state}"
  end

  private def generate_random_string(length = 10)
    ascii_letters = [*'a'..'z', *'A'..'Z']
    (0...length).map { ascii_letters.sample }.join
  end

  def save
    ConcreteMemento.new(@state)
  end

  def restore(memento)
    @state = memento.state
    puts "Originator: My state has changed to: #{@state}"
  end
end

class Memento
  def state
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def name
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def date
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class ConcreteMemento < Memento
  def initialize(state)
    @state = state
    @date = Time.now.strftime('%F %T')
  end

  attr_reader :state

  def name
    "#{@date} / (#{@state[0, 9]}...)"
  end

  attr_reader :date
end

class Caretaker
  def initialize(originator)
    @mementos = []
    @originator = originator
  end

  def backup
    puts "\nCaretaker: Saving Originator's state..."
    @mementos << @originator.save
  end

  def undo
    return if @mementos.empty?

    memento = @mementos.pop
    puts "Caretaker: Restoring state to: #{memento.name}"

    begin
      @originator.restore(memento)
    rescue StandardError
      undo
    end
  end

  def show_history
    puts 'Caretaker: Here\'s the list of mementos:'

    @mementos.each { |memento| puts memento.name }
  end
end

# Client code
originator = Originator.new('Super-duper-super-puper-super.')
caretaker = Caretaker.new(originator)

caretaker.backup
originator.do_something

caretaker.backup
originator.do_something

caretaker.backup
originator.do_something

puts "\n"
caretaker.show_history

puts "\nClient: Now, let's rollback!\n\n"
caretaker.undo

puts "\nClient: Once more!\n\n"
caretaker.undo
```

**File**: `Ruby/src/memento/conceptual/main.rb`

---

## Observer

**Intent**: Lets you define a subscription mechanism to notify multiple objects about any events that happen to the object they're observing.

**When to use**:
- Changes to one object's state may require updating other objects, and the set is unknown or dynamic
- Some objects must observe others temporarily or in specific cases
- Building event-driven systems or pub/sub mechanisms

```ruby
class Subject
  def attach(observer)
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def detach(observer)
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def notify
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class ConcreteSubject < Subject
  attr_accessor :state

  def initialize
    @observers = []
  end

  def attach(observer)
    puts 'Subject: Attached an observer.'
    @observers << observer
  end

  def detach(observer)
    @observers.delete(observer)
  end

  def notify
    puts 'Subject: Notifying observers...'
    @observers.each { |observer| observer.update(self) }
  end

  def some_business_logic
    puts "\nSubject: I'm doing something important."
    @state = rand(0..10)
    puts "Subject: My state has just changed to: #{@state}"
    notify
  end
end

class Observer
  def update(_subject)
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class ConcreteObserverA < Observer
  def update(subject)
    puts 'ConcreteObserverA: Reacted to the event' if subject.state < 3
  end
end

class ConcreteObserverB < Observer
  def update(subject)
    puts 'ConcreteObserverB: Reacted to the event' if subject.state.zero? || subject.state >= 2
  end
end

# Client code
subject = ConcreteSubject.new

observer_a = ConcreteObserverA.new
subject.attach(observer_a)

observer_b = ConcreteObserverB.new
subject.attach(observer_b)

subject.some_business_logic
subject.some_business_logic

subject.detach(observer_a)

subject.some_business_logic
```

**File**: `Ruby/src/observer/conceptual/main.rb`

---

## State

**Intent**: Lets an object alter its behavior when its internal state changes. It appears as if the object changed its class.

**When to use**:
- Object behaves differently depending on current state and has many states
- Class contains massive conditionals controlling behavior based on field values
- Lots of duplicate code across similar states and transitions

```ruby
class Context
  attr_accessor :state

  def initialize(state)
    transition_to(state)
  end

  def transition_to(state)
    puts "Context: Transition to #{state.class}."
    @state = state
    @state.context = self
  end

  def request1
    @state.handle1
  end

  def request2
    @state.handle2
  end
end

class State
  attr_accessor :context

  def handle1
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def handle2
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class ConcreteStateA < State
  def handle1
    puts 'ConcreteStateA handles request1.'
    puts 'ConcreteStateA wants to change the state of the context.'
    @context.transition_to(ConcreteStateB.new)
  end

  def handle2
    puts 'ConcreteStateA handles request2.'
  end
end

class ConcreteStateB < State
  def handle1
    puts 'ConcreteStateB handles request1.'
  end

  def handle2
    puts 'ConcreteStateB handles request2.'
    puts 'ConcreteStateB wants to change the state of the context.'
    @context.transition_to(ConcreteStateA.new)
  end
end

# Client code
context = Context.new(ConcreteStateA.new)
context.request1
context.request2
```

**File**: `Ruby/src/state/conceptual/main.rb`

---

## Strategy

**Intent**: Lets you define a family of algorithms, put each of them into a separate class, and make their objects interchangeable.

**When to use**:
- Want to use different algorithm variants and switch between them at runtime
- Similar classes differ only in their behavior
- Need to isolate algorithm implementation details from business logic
- Eliminating massive conditionals that select algorithm implementations

```ruby
class Context
  attr_writer :strategy

  def initialize(strategy)
    @strategy = strategy
  end

  def strategy=(strategy)
    @strategy = strategy
  end

  def do_some_business_logic
    puts 'Context: Sorting data using the strategy (not sure how it\'ll do it)'
    result = @strategy.do_algorithm(%w[a b c d e])
    print result.join(',')
  end
end

class Strategy
  def do_algorithm(_data)
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class ConcreteStrategyA < Strategy
  def do_algorithm(data)
    data.sort
  end
end

class ConcreteStrategyB < Strategy
  def do_algorithm(data)
    data.sort.reverse
  end
end

# Client code
context = Context.new(ConcreteStrategyA.new)
puts 'Client: Strategy is set to normal sorting.'
context.do_some_business_logic
puts "\n\n"

puts 'Client: Strategy is set to reverse sorting.'
context.strategy = ConcreteStrategyB.new
context.do_some_business_logic
```

**File**: `Ruby/src/strategy/conceptual/main.rb`

---

## Template Method

**Intent**: Defines the skeleton of an algorithm in the superclass but lets subclasses override specific steps of the algorithm without changing its structure.

**When to use**:
- Let clients extend only particular algorithm steps, not the entire algorithm
- Consolidating nearly identical algorithms with minor differences
- Eliminating code duplication by pulling common steps into base class

```ruby
class AbstractClass
  def template_method
    base_operation1
    required_operations1
    base_operation2
    hook1
    required_operations2
    base_operation3
    hook2
  end

  def base_operation1
    puts 'AbstractClass says: I am doing the bulk of the work'
  end

  def base_operation2
    puts 'AbstractClass says: But I let subclasses override some operations'
  end

  def base_operation3
    puts 'AbstractClass says: But I am doing the bulk of the work anyway'
  end

  def required_operations1
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def required_operations2
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def hook1; end

  def hook2; end
end

class ConcreteClass1 < AbstractClass
  def required_operations1
    puts 'ConcreteClass1 says: Implemented Operation1'
  end

  def required_operations2
    puts 'ConcreteClass1 says: Implemented Operation2'
  end
end

class ConcreteClass2 < AbstractClass
  def required_operations1
    puts 'ConcreteClass2 says: Implemented Operation1'
  end

  def required_operations2
    puts 'ConcreteClass2 says: Implemented Operation2'
  end

  def hook1
    puts 'ConcreteClass2 says: Overridden Hook1'
  end
end

# Client code
def client_code(abstract_class)
  abstract_class.template_method
end

puts 'Same client code can work with different subclasses:'
client_code(ConcreteClass1.new)
puts "\n"

puts 'Same client code can work with different subclasses:'
client_code(ConcreteClass2.new)
```

**File**: `Ruby/src/template_method/conceptual/main.rb`

---

## Visitor

**Intent**: Lets you separate algorithms from the objects on which they operate.

**When to use**:
- Need to perform operations on complex structures with different class types
- Extract auxiliary behaviors from domain objects to keep them focused
- Add behaviors that apply inconsistently across hierarchies
- Anticipate multiple future operations on stable object structures

```ruby
class Component
  def accept(_visitor)
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class ConcreteComponentA < Component
  def accept(visitor)
    visitor.visit_concrete_component_a(self)
  end

  def exclusive_method_of_concrete_component_a
    'A'
  end
end

class ConcreteComponentB < Component
  def accept(visitor)
    visitor.visit_concrete_component_b(self)
  end

  def special_method_of_concrete_component_b
    'B'
  end
end

class Visitor
  def visit_concrete_component_a(_element)
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def visit_concrete_component_b(_element)
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class ConcreteVisitor1 < Visitor
  def visit_concrete_component_a(element)
    puts "#{element.exclusive_method_of_concrete_component_a} + ConcreteVisitor1"
  end

  def visit_concrete_component_b(element)
    puts "#{element.special_method_of_concrete_component_b} + ConcreteVisitor1"
  end
end

class ConcreteVisitor2 < Visitor
  def visit_concrete_component_a(element)
    puts "#{element.exclusive_method_of_concrete_component_a} + ConcreteVisitor2"
  end

  def visit_concrete_component_b(element)
    puts "#{element.special_method_of_concrete_component_b} + ConcreteVisitor2"
  end
end

# Client code
def client_code(components, visitor)
  components.each do |component|
    component.accept(visitor)
  end
end

components = [ConcreteComponentA.new, ConcreteComponentB.new]

puts 'The client code works with all visitors via the base Visitor interface:'
visitor1 = ConcreteVisitor1.new
client_code(components, visitor1)

puts 'It allows the same client code to work with different types of visitors:'
visitor2 = ConcreteVisitor2.new
client_code(components, visitor2)
```

**File**: `Ruby/src/visitor/conceptual/main.rb`
