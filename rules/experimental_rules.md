1. Always write a test first. Take a Test Driven Development (TDD) approach.
2. After writing a test ask for confirmation that the test is capturing the desired behavior.
3. Always run tests before and after writing code. At first your test should fail, then write the code to make it pass.
4. Once your tests are passing, run rubycritic to check code quality. If the grade is below an "A", address the issues and re-run until the grade is an "A". You should not change the behavior of the code only the implementation.
5. Always check the coverage after writing code. If the line coverage is below 90%, address the issues and re-run until the coverage is 90%. If the branch coverage is below 90%, address the issues and re-run until the coverage is 90%.
