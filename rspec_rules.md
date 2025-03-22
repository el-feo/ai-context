NotebookLLM Prompt: create a set of rules that can be used to guide an LLM when writing RSpec tests, provide an example for each rule.

Here are a set of rules to guide an LLM when writing RSpec tests, along with examples drawn from the provided sources:

Rule 1: Clearly Describe the Method or Class Under Test. Use `describe` with the Ruby documentation convention (`#` for instance methods and `.` or `::` for class methods) to specify what is being tested.

- Example (Instance Method):

  ```ruby
  RSpec.describe User do
    describe '#authenticate' do
      # ... tests for the authenticate instance method ...
    end
  end
  ```

- Example (Class Method):
  ```ruby
  RSpec.describe User do
    describe '.find_by_email' do
      # ... tests for the find_by_email class method ...
    end
  end
  ```

Rule 2: Organize Tests by Scenario Using `context`. Use `context` to group tests under specific conditions or situations to improve readability and organization.

- Example:

  ```ruby
  RSpec.describe User do
    describe '#authenticate' do
      context 'when the password is correct' do
        # ... tests for correct password ...
      end

      context 'when the password is incorrect' do
        # ... tests for incorrect password ...
      end

      context 'when the user is an admin' do
        # ... tests for admin user ...
      end
    end
  end
  ```

Rule 3: Write Short and Descriptive Explanations for Each Test. Each `it` block should have a concise description of the expected behavior.

- Bad Example:

  ```ruby
  it 'does something with the resource and assigns it' do
    expect(response).to respond_with_content_type(:json)
    expect(response).to assign_to(:resource)
  end
  ```

- Good Example (following single expectation rule as well):

  ```ruby
  it 'responds with JSON content type' do
    expect(response).to respond_with_content_type(:json)
  end

  it 'assigns the resource' do
    expect(response).to assign_to(:resource)
  end
  ```

Rule 4: Focus Each Test on a Single Expectation. Each `it` block should ideally assert only one specific behavior to make it easier to pinpoint failures and understand the code.

- Example (Single Expectation):
  ```ruby
  it 'creates a resource' do #
    # ... code to create resource ...
    expect(response).to respond_with_content_type(:json)
  end
  ```

Rule 5: Test All Possible Cases, Including Edge Cases and Invalid Scenarios. Ensure comprehensive testing by covering valid inputs, edge conditions, and invalid inputs.

- Example (Testing Invalid Case):
  ```ruby
  RSpec.describe User do
    describe '#create' do
      context 'when the name is not provided' do
        it 'does not create a user' do
          # ... code to attempt user creation without name ...
          expect(User.count).to eq(0)
        end
      end
    end
  end
  ```

Rule 6: Prefer the `expect` Syntax Over `should`. For new projects, always use the `expect` syntax for assertions as it is the recommended and more modern approach.

- Bad Example:

  ```ruby
  it 'creates a resource' do
    response.should respond_with_content_type(:json)
  end
  ```

- Good Example:
  ```ruby
  it 'creates a resource' do
    expect(response).to respond_with_content_type(:json)
  end
  ```

Rule 7: Utilize `subject` to Reduce Repetition. If multiple tests relate to the same subject, define it once using `subject {}` to DRY up your tests.

- Bad Example:

  ```ruby
  it 'matches a certain message' do
    expect(assigns('message')).to match(/it was born in Belville/)
  end
  ```

- Good Example:
  ```ruby
  subject { assigns('message') }
  it { is_expected.to match(/it was born in Billville/) } #
  ```

Rule 8: Use `let` and `let!` for Efficient Variable Assignment. Use `let` for lazy-loaded variables and `let!` for variables that need to be created before each test. This avoids the verbosity of `before` blocks for simple assignments.

- Example (`let`):

  ```ruby
  describe '#index' do
    let(:user) { FactoryBot.create(:user) }

    it 'assigns the current user' do
      sign_in user
      get :index
      expect(assigns(:current_user)).to eq(user)
    end
  end
  ```

- Example (`let!`):

  ```ruby
  describe 'GET /devices' do
    let!(:resource) { FactoryBot.create(:device, created_from: user.id) } #
    let!(:uri) { '/devices' }

    # ... tests using resource and uri ...
  end
  ```

Rule 9: Create Only the Necessary Test Data. Avoid creating excessive or unnecessary data, as this can make your test suite slower and harder to manage.

- Good Example (creating only 2 users when needed):
  ```ruby
  describe '.top' do
    before { FactoryBot.create_list(:user, 3) }
    it { expect(User.top(2)).to have(2).item } #
  end
  ```

Rule 10: Prefer Factories Over Fixtures for Data Setup. Use factories (e.g., with FactoryBot) for creating test data as they are more flexible and easier to control than fixtures.

- Bad Example (using direct creation):

  ```ruby
  it 'creates a user' do
    user = User.create(name: 'Genoveffa', surname: 'Piccolina', city: 'Billyville', birth: '17 Agoust 1982', active: true)
    expect(user).to be_persisted
  end
  ```

- Good Example (using FactoryBot):
  ```ruby
  it 'creates a user' do
    user = FactoryBot.create(:user)
    expect(user).to be_persisted
  end
  ```

Rule 11: Choose Readable and Expressive Matchers. Utilize RSpec's built-in matchers that clearly convey the expected outcome. Explore the available matchers to find the most suitable one.

- Bad Example:

  ```ruby
  it 'raises a document not found error' do
    expect { model.save! }.to raise_error(Mongoid::Errors::DocumentNotFound) #
  end
  ```

- Good Example:
  ```ruby
  it 'raises a Mongoid::Errors::DocumentNotFound error' do
    expect { model.save! }.to raise_error(Mongoid::Errors::DocumentNotFound) #
  end
  ```

Rule 12: Test Observable Behavior Rather Than Implementation Details. Focus on verifying what the user or other parts of the system will observe, rather than how the behavior is implemented.

- Example (Testing Behavior):

  ```ruby
  it 'increases the order total when a product is added' do
    order = Order.new
    product = Product.new(price: 10)
    order.add_product(product)
    expect(order.total).to eq(10)
  end
  ```

- Avoid (Testing Implementation Detail):
  ```ruby
  it 'calls the internal add_item method' do # Less ideal, implementation-focused
    order = Order.new
    expect(order).to receive(:add_item).once
    order.add_product(Product.new(price: 10))
  end
  ```

Rule 13: Avoid Using `should` in Test Descriptions. Use the third person present tense to describe what the code does.

- Bad Example:

  ```ruby
  it 'should not change timings' do
    expect(consumption.occur_at).to eq(valid.occur_at)
  end
  ```

- Good Example:
  ```ruby
  it 'does not change timings' do #
    expect(consumption.occur_at).to eq(valid.occur_at)
  end
  ```
