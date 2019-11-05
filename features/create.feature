Feature: Create WordPress project

  Scenario: Create a project
    When I run `wp leonis create hello-world`
    Then STDOUT should not be empty
    And the hello-world/.gitignore file should exist
    And the hello-world/wp-cli.yml file should contain:
      """
        - require: bin/command.php
      """
