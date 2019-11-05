Feature: WordPress create project

  Scenario: Empty dir
    Given an empty directory
    And an empty cache
    When I run `wp alias new "Hello World"`
    Then STDOUT should not be empty
    And the hello-world/.gitignore file should exist
    And the hello-world/wp-cli.yml file should contain:
      """
        - require: bin/commands.php
      """

  #Scenario: Create a project
  #  When I run `wp alias new hello-world`
  #  Then STDOUT should not be empty
  #  And the hello-world/wp-cli.yml file should exist
  #  And the hello-world/wp-cli.yml file should contain:
  #    """
  #      - require: bin/commands.php
  #    """

  #Scenario: Empty dir
  #  Given an empty directory
  #  And an empty cache
  #  When I run `wp alias new hello-world`
  #  Then STDOUT should not be empty
  #  And the hello-world/.gitignore file should exist
  #  And the hello-world/.gitignore file should contain:
  #    """
  #    .DS_Store
  #    """
