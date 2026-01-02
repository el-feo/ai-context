# Structural Patterns Reference

Detailed Ruby implementations for structural design patterns.

## Adapter

**Intent**: Allows objects with incompatible interfaces to collaborate.

**When to use**:
- Existing class interface isn't compatible with your code
- Integrating third-party, legacy, or dependency-heavy classes you cannot modify
- Multiple subclasses lack common methods and you want to avoid code duplication

```ruby
class Target
  def request
    "Target: The default target's behavior."
  end
end

class Adaptee
  def specific_request
    '.eetpadA eht fo roivaheb laicepS'
  end
end

class Adapter < Target
  def initialize(adaptee)
    @adaptee = adaptee
  end

  def request
    "Adapter: (TRANSLATED) #{@adaptee.specific_request.reverse}"
  end
end

# Client code
def client_code(target)
  print target.request
end

puts 'Client: I can work just fine with the Target objects:'
target = Target.new
client_code(target)
puts "\n\n"

adaptee = Adaptee.new
puts "Client: The Adaptee class has a weird interface. See, I don't understand it:"
puts "Adaptee: #{adaptee.specific_request}"
puts "\n"

puts 'Client: But I can work with it via the Adapter:'
adapter = Adapter.new(adaptee)
client_code(adapter)
```

**Files**:
- Conceptual: `Ruby/src/adapter/conceptual/main.rb`
- Real World (speed conversion): `Ruby/src/adapter/real_world/main.rb`

---

## Bridge

**Intent**: Lets you split a large class or a set of closely related classes into two separate hierarchies—abstraction and implementation—which can be developed independently.

**When to use**:
- Have a monolithic class with multiple functionality variants (e.g., database server support)
- Need to extend a class in independent orthogonal dimensions
- Need to switch implementations at runtime

```ruby
class Abstraction
  def initialize(implementation)
    @implementation = implementation
  end

  def operation
    "Abstraction: Base operation with:\n"\
    "#{@implementation.operation_implementation}"
  end
end

class ExtendedAbstraction < Abstraction
  def operation
    "ExtendedAbstraction: Extended operation with:\n"\
    "#{@implementation.operation_implementation}"
  end
end

class Implementation
  def operation_implementation
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class ConcreteImplementationA < Implementation
  def operation_implementation
    'ConcreteImplementationA: Here\'s the result on the platform A.'
  end
end

class ConcreteImplementationB < Implementation
  def operation_implementation
    'ConcreteImplementationB: Here\'s the result on the platform B.'
  end
end

# Client code
def client_code(abstraction)
  print abstraction.operation
end

implementation = ConcreteImplementationA.new
abstraction = Abstraction.new(implementation)
client_code(abstraction)
puts "\n\n"

implementation = ConcreteImplementationB.new
abstraction = ExtendedAbstraction.new(implementation)
client_code(abstraction)
```

**File**: `Ruby/src/bridge/conceptual/main.rb`

---

## Composite

**Intent**: Lets you compose objects into tree structures and then work with these structures as if they were individual objects.

**When to use**:
- Core model fits a tree structure of simple elements and containers
- Client code should treat individual objects and compositions uniformly
- Need recursive operations over hierarchical structures

```ruby
class Component
  def parent
    @parent
  end

  def parent=(parent)
    @parent = parent
  end

  def add(component)
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def remove(component)
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def composite?
    false
  end

  def operation
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class Leaf < Component
  def operation
    'Leaf'
  end
end

class Composite < Component
  def initialize
    @children = []
  end

  def add(component)
    @children << component
    component.parent = self
  end

  def remove(component)
    @children.delete(component)
    component.parent = nil
  end

  def composite?
    true
  end

  def operation
    results = []
    @children.each { |child| results << child.operation }
    "Branch(#{results.join('+')})"
  end
end

# Client code
def client_code(component)
  puts "RESULT: #{component.operation}"
end

def client_code2(component1, component2)
  component1.add(component2) if component1.composite?
  print "RESULT: #{component1.operation}"
end

simple = Leaf.new
puts 'Client: I\'ve got a simple component:'
client_code(simple)
puts "\n"

tree = Composite.new
branch1 = Composite.new
branch1.add(Leaf.new)
branch1.add(Leaf.new)
branch2 = Composite.new
branch2.add(Leaf.new)
tree.add(branch1)
tree.add(branch2)
puts 'Client: Now I\'ve got a composite tree:'
client_code(tree)
puts "\n"

puts 'Client: I don\'t need to check component classes even when managing the tree:'
client_code2(tree, simple)
```

**File**: `Ruby/src/composite/conceptual/main.rb`

---

## Decorator

**Intent**: Lets you attach new behaviors to objects by placing these objects inside special wrapper objects that contain the behaviors.

**When to use**:
- Need to assign extra behaviors at runtime without modifying code that uses the objects
- Extending behavior when inheritance is problematic (final classes, excessive subclasses)
- Combining multiple behaviors flexibly

```ruby
class Component
  def operation
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class ConcreteComponent < Component
  def operation
    'ConcreteComponent'
  end
end

class Decorator < Component
  attr_accessor :component

  def initialize(component)
    @component = component
  end

  def operation
    @component.operation
  end
end

class ConcreteDecoratorA < Decorator
  def operation
    "ConcreteDecoratorA(#{@component.operation})"
  end
end

class ConcreteDecoratorB < Decorator
  def operation
    "ConcreteDecoratorB(#{@component.operation})"
  end
end

# Client code
def client_code(component)
  print "RESULT: #{component.operation}"
end

simple = ConcreteComponent.new
puts 'Client: I\'ve got a simple component:'
client_code(simple)
puts "\n\n"

# Decorators can wrap not only simple components but other decorators as well
decorator1 = ConcreteDecoratorA.new(simple)
decorator2 = ConcreteDecoratorB.new(decorator1)
puts 'Client: Now I\'ve got a decorated component:'
client_code(decorator2)
```

**File**: `Ruby/src/decorator/conceptual/main.rb`

---

## Facade

**Intent**: Provides a simplified interface to a library, a framework, or any other complex set of classes.

**When to use**:
- Need to offer basic access to a complex subsystem
- Subsystems are becoming more sophisticated and require increased configuration
- Structuring subsystems in layers with controlled communication

```ruby
class Facade
  def initialize(subsystem1, subsystem2)
    @subsystem1 = subsystem1 || Subsystem1.new
    @subsystem2 = subsystem2 || Subsystem2.new
  end

  def operation
    results = []
    results << 'Facade initializes subsystems:'
    results << @subsystem1.operation1
    results << @subsystem2.operation1
    results << 'Facade orders subsystems to perform the action:'
    results << @subsystem1.operation_n
    results << @subsystem2.operation_z
    results.join("\n")
  end
end

class Subsystem1
  def operation1
    'Subsystem1: Ready!'
  end

  def operation_n
    'Subsystem1: Go!'
  end
end

class Subsystem2
  def operation1
    'Subsystem2: Get ready!'
  end

  def operation_z
    'Subsystem2: Fire!'
  end
end

# Client code
def client_code(facade)
  print facade.operation
end

subsystem1 = Subsystem1.new
subsystem2 = Subsystem2.new
facade = Facade.new(subsystem1, subsystem2)
client_code(facade)
```

**File**: `Ruby/src/facade/conceptual/main.rb`

---

## Flyweight

**Intent**: Lets you fit more objects into the available amount of RAM by sharing common parts of state between multiple objects instead of keeping all of the data in each object.

**When to use**:
- Program must support huge numbers of objects that barely fit in RAM
- Many objects contain duplicate state that can be extracted and shared
- Memory optimization is critical

```ruby
class Flyweight
  def initialize(shared_state)
    @shared_state = shared_state
  end

  def operation(unique_state)
    s = @shared_state.to_json
    u = unique_state.to_json
    print "Flyweight: Displaying shared (#{s}) and unique (#{u}) state."
  end
end

class FlyweightFactory
  def initialize(initial_flyweights)
    @flyweights = {}
    initial_flyweights.each do |state|
      @flyweights[get_key(state)] = Flyweight.new(state)
    end
  end

  def get_key(state)
    state.sort.join('_')
  end

  def get_flyweight(shared_state)
    key = get_key(shared_state)

    if @flyweights.key?(key)
      puts 'FlyweightFactory: Reusing existing flyweight.'
    else
      puts 'FlyweightFactory: Can\'t find a flyweight, creating new one.'
      @flyweights[key] = Flyweight.new(shared_state)
    end

    @flyweights[key]
  end

  def list_flyweights
    count = @flyweights.size
    puts "FlyweightFactory: I have #{count} flyweights:"
    print @flyweights.keys.join("\n")
  end
end

# Client code
def add_car_to_police_database(factory, plates, owner, brand, model, color)
  puts "\n\nClient: Adding a car to database."
  flyweight = factory.get_flyweight([brand, model, color])
  flyweight.operation([plates, owner])
end

factory = FlyweightFactory.new([
  %w[Chevrolet Camaro2018 pink],
  %w[Mercedes C300 black],
  %w[Mercedes C500 red],
  %w[BMW M5 red],
  %w[BMW X6 white]
])

factory.list_flyweights

add_car_to_police_database(factory, 'CL234IR', 'James Doe', 'BMW', 'M5', 'red')
add_car_to_police_database(factory, 'CL234IR', 'James Doe', 'BMW', 'X1', 'red')

puts "\n\n"
factory.list_flyweights
```

**File**: `Ruby/src/flyweight/conceptual/main.rb`

---

## Proxy

**Intent**: Lets you provide a substitute or placeholder for another object. A proxy controls access to the original object, allowing you to perform something either before or after the request gets through to the original object.

**When to use**:
- Lazy initialization - delay creating resource-intensive objects
- Access control - restrict which clients can use specific services
- Remote services - handle network communication transparently
- Logging/caching - maintain request histories or cache results
- Smart references - manage object lifecycles

```ruby
class Subject
  def request
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end
end

class RealSubject < Subject
  def request
    puts 'RealSubject: Handling request.'
  end
end

class Proxy < Subject
  def initialize(real_subject)
    @real_subject = real_subject
  end

  def request
    return unless check_access

    @real_subject.request
    log_access
  end

  def check_access
    puts 'Proxy: Checking access prior to firing a real request.'
    true
  end

  def log_access
    print 'Proxy: Logging the time of request.'
  end
end

# Client code
def client_code(subject)
  subject.request
end

puts 'Client: Executing the client code with a real subject:'
real_subject = RealSubject.new
client_code(real_subject)

puts "\n"

puts 'Client: Executing the same client code with a proxy:'
proxy = Proxy.new(real_subject)
client_code(proxy)
```

**File**: `Ruby/src/proxy/conceptual/main.rb`
