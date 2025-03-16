Based on the principles and practices demonstrated in "99 Bottles of OOP," here is a set of rules that can guide an LLM when writing Ruby code:

*   **Prioritize Simple and Understandable Code**: Aim for code that is easy to read and comprehend, even if it means being more verbose initially. Avoid being **incomprehensibly concise** or indulging in **unnecessary complexity**. The goal is to quickly reach a working state ("green") while prioritizing understandability.

*   **Practice Test-Driven Development (TDD)**: Follow the **Red/Green/Refactor cycle**. Write tests first that thoroughly describe the problem, then write the minimum code to pass these tests, and finally refactor the code to improve its design. The exercises in the book rely on **Minitest**.

*   **Address Requirements Directly and Incrementally**: Focus on meeting the **current requirements** without speculating about future needs. When a new requirement arrives, it indicates exactly how the code should change. **Clarify requirements** and write the minimum necessary code.

*   **Refactor Systematically to Improve Design**: Continuously look for **code smells** and apply **refactoring techniques** to improve the code's structure, reduce duplication (DRY - Don't Repeat Yourself), and extract abstractions. The **Flocking Rules** (Select alike, find smallest difference, make simplest change) can guide refactoring.

*   **Embrace Object-Oriented Principles**: Design code around **objects** that communicate through **messages**. Identify responsibilities and encapsulate them within classes. Consider extracting classes to model abstractions.

*   **Choose Intention-Revealing Names**: Select names for classes, methods, and variables that clearly communicate their purpose and role. Name methods at "one higher level of abstraction than their current implementation". **Intention-revealing code** is built from thoughtful acts, like choosing `case` over `if` when conditions are fundamentally the same.

*   **Manage Duplication Strategically**: While **DRY is generally good**, it's sometimes better to manage temporary duplication than to create incorrect abstractions prematurely. Wait for **unambiguous examples** before creating abstractions. In testing, it is often best to **"just write it down"** rather than trying to be too DRY.

*   **Strive for Code That is Open for Extension and Closed for Modification**: Design code that can be easily extended to meet new requirements without requiring modification of existing code. Recognize when code is not "open" to new requirements and address the underlying **code smells**.

*   **Apply Polymorphism to Handle Variations**: Replace conditional logic (like `if` and `case` statements) with **polymorphism** by creating different classes that respond to the same messages in different ways. Factories can be used to manufacture the correct objects based on certain conditions.

*   **Adhere to the Law of Demeter**: Minimize the number of dependencies an object has on other objects. An object should only talk to its immediate neighbors. Fix violations by adding forwarding methods if necessary.

*   **Write Unit Tests That Tell a Story**: Unit tests should demonstrate and confirm a class's direct responsibilities and do nothing else. Aim for the **fastest tests possible**, using the **fewest number necessary** and the **most intention-revealing expectations**.
