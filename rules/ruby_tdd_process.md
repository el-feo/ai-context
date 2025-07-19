# Ruby on Rails: Test-Driven Development Process

This document outlines a standardized, test-driven development (TDD) process for creating new features and modifying existing ones within a Ruby on Rails application. The prescribed stack includes RSpec for testing, SimpleCov for code coverage analysis, and Reek/RuboCop for code quality and style enforcement.

## Core Principle: Red-Green-Refactor-Lint

The entire workflow is an extension of the classic Red-Green-Refactor cycle. Each phase is a distinct step with a clear goal.

* **RED**: Write a test that describes the desired functionality or exposes a bug. This test *must* fail initially because the implementation code does not yet exist or is incorrect.
* **GREEN**: Write the absolute minimum amount of code required to make the failing test pass. The focus is on correctness, not elegance.
* **REFACTOR**: Improve the structure, readability, and efficiency of the code you just wrote without changing its external behavior. The tests should continue to pass.
* **LINT**: After refactoring, run static analysis tools to catch code smells, style violations, and potential issues. Fix them before finalizing the feature.

---

## Process for a NEW Feature

Follow these steps sequentially when building a new feature from scratch.

### Rule 1: Write a Failing Test (The "Red" Phase)
1.  **Identify the smallest piece of required functionality.** For example, if building a user authentication system, the first piece might be "a user can be created with a valid email and password."
2.  **Create a new RSpec file** in the appropriate directory (e.g., `spec/models/user_spec.rb`, `spec/requests/sessions_spec.rb`).
3.  **Write a descriptive test case** using `it '...' do`. The description should clearly state what the code is expected to do.
4.  **Write assertions** using RSpec's `expect` syntax that define the success criteria for the functionality.
5.  **Run the test suite:**
    ```bash
    bundle exec rspec spec/path/to/your_new_spec.rb
    ```
6.  **Confirm the test fails.** The failure message should indicate that the functionality is not implemented (e.g., `NoMethodError`, `uninitialized constant`, or a failed assertion). This is the expected "Red" state.

### Rule 2: Make the Test Pass (The "Green" Phase)
1.  **Write the simplest possible code** in your application (e.g., in the model, controller, or service object) that will satisfy the test's assertions.
2.  **Do not add any logic that the test does not explicitly require.** Avoid premature optimization or adding functionality "just in case."
3.  **Run the specific test again.**
    ```bash
    bundle exec rspec spec/path/to/your_new_spec.rb
    ```
4.  **Iterate on the implementation code** until the test passes. If you get stuck, you may be trying to do too much. Simplify the implementation further.
5.  **Confirm the test is "Green."**

### Rule 3: Refactor the Implementation
1.  **Review the code you just wrote.** Is it clear? Is it efficient? Is there duplication?
2.  **Improve the code's design without changing its behavior.** This might involve renaming variables, extracting methods, or removing redundant logic.
3.  **Re-run the test(s) after each small refactoring change** to ensure you haven't broken anything. The tests are your safety net.
    ```bash
    bundle exec rspec spec/path/to/your_new_spec.rb
    ```
4.  **All tests must continue to pass.**

### Rule 4: Verify and Improve Test Coverage
1.  **Run the entire test suite with SimpleCov enabled:**
    ```bash
    bundle exec rspec
    ```
2.  **Open the coverage report:** `open coverage/index.html`.
3.  **Analyze the report.** Look for:
    * Untested lines in the new code you added.
    * Conditional logic (if/else, case statements) where not all branches are tested.
4.  **Add more tests** to cover any missed lines or logic branches. Return to Rule 1 to write a new failing test for the uncovered case, and then proceed through the cycle again. The goal is to achieve 100% coverage for the new code.

### Rule 5: Lint and Clean the Code
1.  **Run Reek and RuboCop** on the files you have changed:
    ```bash
    bundle exec reek app/path/to/your/file.rb
    bundle exec rubocop app/path/to/your/file.rb
    ```
2.  **Review the output from the linters.** They will report "code smells" (Reek) and style violations (RuboCop).
3.  **Fix all reported issues.** This ensures the code is maintainable, readable, and adheres to community standards.
4.  **Re-run the tests after fixing linting issues** to ensure no functionality was accidentally broken.

### Rule 6: Final Verification
1.  **Run the entire test suite one last time.**
    ```bash
    bundle exec rspec
    ```
2.  **Ensure all tests pass.** The feature is now complete, tested, documented by tests, and clean. It is ready for commit.

---

## Process for an EXISTING Feature (Modification or Bug Fix)

Follow these steps when making a small change or fixing a bug in an existing feature.

### Rule 1: Isolate and Describe the Change with a Test
1.  **If fixing a bug:** Write a new test that specifically fails because of the bug. This test proves the bug exists and will confirm when it is fixed.
2.  **If adding a small enhancement:** Write a new test that describes the new behavior. This test will fail because the enhancement is not yet implemented.
3.  **Run the new test and confirm it fails as expected (Red).** This is a critical step to ensure your test is correctly targeting the issue.

### Rule 2: Implement the Code Change
1.  **Navigate to the relevant source code file(s).**
2.  **Make the necessary code change** to either fix the bug or implement the enhancement.

### Rule 3: Run Tests and Iterate (Green)
1.  **Run the test you just wrote, along with any other relevant tests** for that part of the application.
    ```bash
    bundle exec rspec spec/path/to/relevant_spec.rb
    ```
2.  **If the test fails, analyze the error and iterate on your code change.**
3.  **If the test passes, but you suspect your change might have unintended side effects, run the entire test suite.**
    ```bash
    bundle exec rspec
    ```
4.  **Ensure all tests pass (Green).** If other tests now fail, your change has broken existing functionality. You must fix the implementation until all tests pass. Do not modify existing tests unless they no longer reflect the true intent of the feature.

### Rule 4: Check Coverage
1.  **Run RSpec with SimpleCov** and review the coverage report (`coverage/index.html`).
2.  **Ensure your changes are fully covered.** If your change introduced new conditional logic, make sure you have tests for all branches.
3.  **Add tests if necessary** to increase coverage on the modified code.

### Rule 5: Lint the Changes
1.  **Run Reek and RuboCop on the files you modified.**
    ```bash
    bundle exec reek app/path/to/modified/file.rb
    bundle exec rubocop app/path/to/modified/file.rb
    ```
2.  **Fix any new issues** that your changes introduced.

### Rule 6: Final Test Run
1.  **Execute the full test suite one final time.**
    ```bash
    bundle exec rspec
    ```
2.  **Confirm a 100% passing build.** The modification is now complete and ready for commit.
