Always refer @CODING-STANDARDS.md file before making any changes.

refer to 'quickshell' skill.

- Do not preserve complexity just because it already exists. Do not introduce machinery because it looks architecturally impressive. Understand the real constraint, then fight for the smallest model that makes the correct behavior unsurprising.
- Channel both "measure twice, cut once" and "yagni". Fight scope creep. Try to honor the dev's intent in both a minimal and realistic fashion.
- Follow SOLID principles where they genuinely improve the design. Do not force abstractions or patterns just to satisfy a principle. Prefer simple, focused, and maintainable components.
- Do not make assumptions. Make sure everything is correct before making changes.
- Assume you know nothing and always refer to the Quickshell and QML documentation to understand how something should be implemented. Follow the documented, correct approach rather than guessing or relying on assumptions.
- Always implement things using Quickshell-native functionality whenever possible. If something cannot be done natively, discuss the approach with the maintainer before applying any changes.
- When a piece of code needs to be repeated more than twice, follow the DRY principle and refactor it.
- Comments describe how a thing is used, and move when the code moves. To be used mostly to describe functions, not to annotate every line of behavior.
- If a rule here fights the task in front of you, say so loudly and get a human sign-off before breaking it.

docs:
- [Quickshell introduction](https://quickshell.org/docs/v0.3.0/guide/introduction/)
- [Type reference](https://quickshell.org/docs/v0.3.0/types/)
- [Qt QML documents](https://doc.qt.io/qt-6/qtqml-documents-topic.html)
- [Qt item size and positioning](https://doc.qt.io/qt-6/qtquick-positioning.html)
