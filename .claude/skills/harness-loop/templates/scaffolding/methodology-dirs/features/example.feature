Feature: Example feature
  As a <role>
  I want <capability>
  So that <benefit>

  # Background runs before every Scenario in this file.
  # Keep it short — long backgrounds mean the feature's setup is too coupled.
  Background:
    Given the system is in a known state
    And a user exists with role "<role>"

  # A single Scenario: one concrete path through the feature.
  Scenario: example scenario
    Given <initial state>
    When <action>
    Then <expected outcome>
    And <secondary observable>

  # Scenario Outline + Examples: the same logical path over multiple inputs.
  # Each row in Examples: runs the Scenario once, substituting <parameter>.
  Scenario Outline: data-driven example
    Given <initial state with <parameter>>
    When <action>
    Then <expected outcome>

    Examples:
      | parameter |
      | value1    |
      | value2    |
      | value3    |

  # Scenarios can be tagged for selective runs (e.g., @slow, @integration).
  # CI typically runs @smoke on every push, @integration nightly.
  @smoke
  Scenario: a tagged scenario
    Given <initial state>
    When <action>
    Then <expected outcome>
