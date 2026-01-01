# Custom Cops Guide

Guide to creating custom RuboCop cops for project-specific rules.

## Basic Cop Structure

```ruby
# lib/rubocop/cop/custom/example_cop.rb
module RuboCop
  module Cop
    module Custom
      class ExampleCop < Base
        extend AutoCorrector
        
        MSG = 'Use preferred method instead'
        
        def_node_matcher :old_method?, <<~PATTERN
          (send ... :old_method ...)
        PATTERN
        
        def on_send(node)
          return unless old_method?(node)
          
          add_offense(node) do |corrector|
            corrector.replace(node, corrected_code(node))
          end
        end
        
        private
        
        def corrected_code(node)
          # Generate corrected code
        end
      end
    end
  end
end
```

## Configuration

```yaml
# .rubocop.yml
require:
  - ./lib/rubocop/cop/custom/example_cop.rb

Custom/ExampleCop:
  Enabled: true
  Description: 'Use preferred method'
```

## AST Exploration

```bash
# View AST for code
ruby-parse -e "your_code_here"

# Or use RuboCop's built-in
rubocop --debug your_file.rb
```

## Testing

```ruby
# spec/rubocop/cop/custom/example_cop_spec.rb
RSpec.describe RuboCop::Cop::Custom::ExampleCop do
  subject(:cop) { described_class.new }
  
  it 'registers offense' do
    expect_offense(<<~RUBY)
      old_method
      ^^^^^^^^^^ Use preferred method instead
    RUBY
  end
  
  it 'autocorrects' do
    expect_correction(<<~RUBY)
      # Original code
      RUBY
      # Corrected code
      RUBY
    )
  end
end
```

## Resources

- [RuboCop AST](https://github.com/rubocop/rubocop-ast)
- [Node Pattern](https://github.com/rubocop/rubocop/blob/master/docs/modules/ROOT/pages/node_pattern.adoc)
- [Development Guide](https://docs.rubocop.org/rubocop/development.html)
