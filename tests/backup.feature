Feature: Backup functionality

  Scenario: Successful backup
    Given I have a backup job file
    When I pass the job file to backup-buddy as an argument 
    Then I will see my files are backed up in the desired folder
