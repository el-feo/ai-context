# Creational Patterns Reference

Detailed Ruby implementations for creational design patterns.

## Factory Method

**Intent**: Provides an interface for creating objects in a superclass, but allows subclasses to alter the type of objects that will be created.

**When to use**:
- Cannot predict exact object types your code requires beforehand
- Want library/framework users to extend components through inheritance
- Need to reuse expensive objects through pooling

```ruby
class Creator
  def factory_method
    raise NotImplementedError, "#{self.class} has not implemented method '#{__method__}'"
  end

  def some_operation
    product = factory_method
    "Creator: The same creator's code has just worked with #{product.operation}"
  end
end

class ConcreteCreator1 < Creator
  def factory_method
    ConcreteProduct1.new
  end
end

class ConcreteCreator2 < Creator
  def factory_method
    ConcreteProduct2.new
  end
end

class Product
  def operation
    raise NotImplementedError
  end
end

class ConcreteProduct1 < Product
  def operation
    '{Result of the ConcreteProduct1}'
  end
end

class ConcreteProduct2 < Product
  def operation
    '{Result of the ConcreteProduct2}'
  end
end

# Client code
def client_code(creator)
  print "Client: I'm not aware of the creator's class, but it still works.\n"\
        "#{creator.some_operation}"
end

client_code(ConcreteCreator1.new)
client_code(ConcreteCreator2.new)
```

**File**: `Ruby/src/factory_method/conceptual/main.rb`

---

## Abstract Factory

**Intent**: Lets you produce families of related objects without specifying their concrete classes.

**When to use**:
- Code must work with various product families without depending on concrete classes
- Want to allow future extensibility for new product variants
- A class with multiple Factory Methods is becoming unwieldy

```ruby
class AbstractFactory
  def create_product_a
    raise NotImplementedError
  end

  def create_product_b
    raise NotImplementedError
  end
end

class ConcreteFactory1 < AbstractFactory
  def create_product_a
    ConcreteProductA1.new
  end

  def create_product_b
    ConcreteProductB1.new
  end
end

class ConcreteFactory2 < AbstractFactory
  def create_product_a
    ConcreteProductA2.new
  end

  def create_product_b
    ConcreteProductB2.new
  end
end

class AbstractProductA
  def useful_function_a
    raise NotImplementedError
  end
end

class ConcreteProductA1 < AbstractProductA
  def useful_function_a
    'The result of the product A1.'
  end
end

class ConcreteProductA2 < AbstractProductA
  def useful_function_a
    'The result of the product A2.'
  end
end

class AbstractProductB
  def useful_function_b
    raise NotImplementedError
  end

  def another_useful_function_b(collaborator)
    raise NotImplementedError
  end
end

class ConcreteProductB1 < AbstractProductB
  def useful_function_b
    'The result of the product B1.'
  end

  def another_useful_function_b(collaborator)
    result = collaborator.useful_function_a
    "The result of the B1 collaborating with the (#{result})"
  end
end

# Client code
def client_code(factory)
  product_a = factory.create_product_a
  product_b = factory.create_product_b
  puts product_b.useful_function_b
  puts product_b.another_useful_function_b(product_a)
end

client_code(ConcreteFactory1.new)
client_code(ConcreteFactory2.new)
```

**File**: `Ruby/src/abstract_factory/conceptual/main.rb`

---

## Builder

**Intent**: Lets you construct complex objects step by step. Allows producing different types and representations using the same construction code.

**When to use**:
- Eliminating telescoping constructors (constructors with many optional parameters)
- Creating different representations of a product using similar construction steps
- Building complex composite structures like trees

```ruby
class Builder
  def produce_part_a
    raise NotImplementedError
  end

  def produce_part_b
    raise NotImplementedError
  end

  def produce_part_c
    raise NotImplementedError
  end
end

class ConcreteBuilder1 < Builder
  def initialize
    reset
  end

  def reset
    @product = Product1.new
  end

  def product
    product = @product
    reset
    product
  end

  def produce_part_a
    @product.add('PartA1')
  end

  def produce_part_b
    @product.add('PartB1')
  end

  def produce_part_c
    @product.add('PartC1')
  end
end

class Product1
  def initialize
    @parts = []
  end

  def add(part)
    @parts << part
  end

  def list_parts
    "Product parts: #{@parts.join(', ')}"
  end
end

class Director
  attr_accessor :builder

  def initialize
    @builder = nil
  end

  def builder=(builder)
    @builder = builder
  end

  def build_minimal_viable_product
    @builder.produce_part_a
  end

  def build_full_featured_product
    @builder.produce_part_a
    @builder.produce_part_b
    @builder.produce_part_c
  end
end

# Client code
director = Director.new
builder = ConcreteBuilder1.new
director.builder = builder

puts 'Standard basic product:'
director.build_minimal_viable_product
puts builder.product.list_parts

puts 'Standard full featured product:'
director.build_full_featured_product
puts builder.product.list_parts

# Custom product without Director
puts 'Custom product:'
builder.produce_part_a
builder.produce_part_b
puts builder.product.list_parts
```

**File**: `Ruby/src/builder/conceptual/main.rb`

---

## Prototype

**Intent**: Lets you copy existing objects without making your code dependent on their classes.

**When to use**:
- Code receives objects from third-party sources through interfaces only and needs to copy them
- Reducing subclass proliferation when you have complex classes requiring repeated configuration

**Ruby note**: Use `Marshal.load(Marshal.dump(object))` for deep copying.

```ruby
class Prototype
  attr_accessor :primitive, :component, :circular_reference

  def clone
    @component = deep_copy(@component)
    @circular_reference = deep_copy(@circular_reference)
    @circular_reference.prototype = self
    deep_copy(self)
  end

  private

  def deep_copy(object)
    Marshal.load(Marshal.dump(object))
  end
end

class ComponentWithBackReference
  attr_accessor :prototype

  def initialize(prototype)
    @prototype = prototype
  end
end

# Client code
p1 = Prototype.new
p1.primitive = 245
p1.component = Time.now
p1.circular_reference = ComponentWithBackReference.new(p1)

p2 = p1.clone

if p1.primitive == p2.primitive
  puts 'Primitive field values have been carried over to a clone.'
else
  puts 'Primitive field values have not been copied.'
end

if p1.component.equal?(p2.component)
  puts 'Simple component has not been cloned.'
else
  puts 'Simple component has been cloned.'
end

if p1.circular_reference.equal?(p2.circular_reference)
  puts 'Component with back reference has not been cloned.'
else
  puts 'Component with back reference has been cloned.'
end

if p1.circular_reference.prototype.equal?(p2.circular_reference.prototype)
  puts 'Component with back reference is linked to original object.'
else
  puts 'Component with back reference is linked to the clone.'
end
```

**File**: `Ruby/src/prototype/conceptual/main.rb`

---

## Singleton

**Intent**: Lets you ensure that a class has only one instance, while providing a global access point to this instance.

**When to use**:
- Program requires exactly one shared instance accessible across components (database connection, logger)
- Need stricter control over global state than traditional global variables
- Want to restrict object creation

### Thread-Safe Implementation

```ruby
class Singleton
  attr_reader :value

  @instance_mutex = Mutex.new

  private_class_method :new

  def initialize(value)
    @value = value
  end

  def self.instance(value)
    return @instance if @instance

    @instance_mutex.synchronize do
      @instance ||= new(value)
    end

    @instance
  end

  def some_business_logic
    # ...
  end
end

# Test thread safety
def test_singleton(value)
  singleton = Singleton.instance(value)
  puts singleton.value
end

puts "If you see the same value, then singleton was reused (yay!)\n"\
     "If you see different values, then 2 singletons were created (booo!!)\n\n"\
     "RESULT:\n\n"

process1 = Thread.new { test_singleton('FOO') }
process2 = Thread.new { test_singleton('BAR') }
process1.join
process2.join
```

**Key Ruby techniques**:
- `private_class_method :new` - prevents direct instantiation
- `Mutex` for thread safety
- Double-checked locking pattern

**Files**:
- Thread-safe: `Ruby/src/singleton/conceptual/thread_safe/main.rb`
- Non-thread-safe: `Ruby/src/singleton/conceptual/non_thread_safe/main.rb`
