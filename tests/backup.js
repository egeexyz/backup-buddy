const { Given, When, Then } = require('cucumber')

Given('I have a backup job', () => {
  console.log('Create some dummy files to back up')
  console.log('Generate markup for job file')
  console.log('Create temporary job file')
})

When('I pass the job file to backup-buddy as an argument', () => {
  console.log('Save a list of the files, maybe a sha?')
  console.log('Invoke backup-buddy, pass temp job file in as arg')
})

Then('I will see my files are backed up in the desired folder', () => {
  console.log('Ensure source & desired are same')
  console.log('Clean out desired dir')
})
