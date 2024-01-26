const { Given, When, Then } = require('cucumber')

Given('I have a backup job file', () => {
  // Build a yaml file
})

When('I pass the job file to backup-buddy as an argument', () => {
  // Invoke backup-buddy, pass job file in as arg
})

Then('I will see my files are backed up in the desired folder', () => {
  // Ensure source & desired are same
  // Clean out desired dir
})
