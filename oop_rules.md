Drawing on information from "99 Bottles of OOP" and "Practical Object-Oriented Design in Ruby", here is a set of rules that can guide an LLM when writing Ruby code:

1. Prioritize Simple and Understandable Code: Aim for code that is easy to read and comprehend, even if it means being more verbose initially. Avoid being incomprehensibly concise or indulging in unnecessary complexity. The goal is to quickly reach a working state ("green") while prioritizing understandability. Simple code is preferred.

2. Practice Test-Driven Development (TDD): Skip this rule if I use the word "skip_test".Follow the Red/Green/Refactor cycle. Write tests first that thoroughly describe the problem, then write the minimum code to pass these tests, and finally refactor the code to improve its design. Aim for the fastest tests possible, using the fewest number necessary and the most intention-revealing expectations.

3. Design Classes with a Single Responsibility: Each class should have one reason to change. Decide what belongs in a single class. Methods within a class should be cohesive around a single purpose. Focus on isolating responsibilities within classes.

4. Manage Dependencies Carefully: Understand how objects get entangled and strive to keep them apart. Inject dependencies to reduce coupling. Be averse to allowing instance methods to know the names of constants and seek to depend on injected abstractions rather than hard-coded concretions. Recognize and manage the dependency direction.

5. Refactor Systematically to Improve Design: Continuously look for code smells and apply refactoring techniques to improve the code's structure, reduce duplication (DRY - Don't Repeat Yourself), and extract abstractions. The Flocking Rules (Select alike, find smallest difference, make simplest change) can guide refactoring.

6. Embrace Object-Oriented Principles: Design code around objects that communicate through messages. Identify responsibilities and encapsulate them within classes. Consider extracting classes to model abstractions. Aim for code that is open for extension, but closed for modification.

7. Choose Intention-Revealing Names: Select names for classes, methods, and variables that clearly communicate their purpose and role. Name methods at "one higher level of abstraction than their current implementation". Intention-revealing code is built from thoughtful acts.

8. Manage Duplication Strategically: While DRY is generally good, it's sometimes better to manage temporary duplication than to create incorrect abstractions prematurely. Wait for unambiguous examples before creating abstractions.

9. Apply Polymorphism to Handle Variations: Replace conditional logic (like `if` and `case` statements) with polymorphism by creating different classes that respond to the same messages in different ways. Factories can be used to manufacture the correct objects based on certain conditions.

10. Obey the Liskov Substitution Principle (LSP): Subclasses should be substitutable for their superclasses. Trustworthy objects behave as expected.

11. Adhere to the Law of Demeter (LoD): Minimize the number of dependencies an object has on other objects. An object should only talk to its immediate neighbors. Fix violations by adding forwarding methods if necessary.

12. Push Object Creation to the Edge: Seek opportunities to move object creation towards the edges of the application. Expect objects to be created in one place and used in another. Use factories as a mechanism for this.

13. Write Unit Tests That Tell a Story: Unit tests should demonstrate and confirm a class's direct responsibilities and do nothing else. Focus on testing the behavior of objects and verifying roles.

By adhering to these rules, an LLM can generate Ruby code that embodies the principles of good object-oriented design, leading to code that is more maintainable, understandable, and adaptable to future changes, as advocated by both "99 Bottles of OOP" and "Practical Object-Oriented Design in Ruby."
