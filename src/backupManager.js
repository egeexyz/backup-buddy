/* eslint-disable space-before-function-paren */
/* eslint-disable require-jsdoc */
import fs from 'fs'
import path from 'path'
import yaml from 'yaml'
import chalk from 'chalk'
import { spawn } from 'child_process'

// Bb's way of managing the state of a backup is a sane
// and easy to read-and-parse way.
export default class BackupManager {
  name; cmd; workdir
  constructor(jobFilePath) {
    const jobDefinitionContents = fs.readFileSync(jobFilePath, 'utf8')
    const jobDefinition = yaml.parse(jobDefinitionContents)
    this.backupName = jobDefinition.name
    this.backupDestination = jobDefinition.backupDestination
    this.backupPaths = jobDefinition.backupPaths
    this.compress = jobDefinition.metadata.compress || false
    this.rsyncBin = jobDefinition.metadata.bin || '/usr/bin/rsync'
    this.rsyncArgs = jobDefinition.metadata.args || '-avzP --no-links'
    this.rsyncExcludes = ''
    jobDefinition.ignorePatterns.forEach(pattern => { this.rsyncExcludes += `--exclude='${pattern}' ` })
  }

  async cmdHelperAsync(cmd) {
    return new Promise((resolve, reject) => {
      console.debug(`Running command: ${cmd}`)
      const childSpawn = spawn('bash', ['-c', cmd])

      childSpawn.stdout.on('data', data => {
        console.log(chalk.green(data.toString()))
      })

      childSpawn.stderr.on('data', data => {
        console.log(chalk.red(data.toString()))
      })

      childSpawn.on('close', (code) => {
        console.log('Command exited with code:', code)
      })
    })
  }

  compressFolder(srcPath) {
    const tarDest = `${this.backupDestination}/${path.parse(srcPath).name}.tar.gz`
    const tarCmd = `tar ${this.rsyncExcludes} -czvf ${tarDest} ${srcPath}`
    // console.log(tarCmd)
    this.cmdHelperAsync(tarCmd)
  }

  backupFolder(srcPath) {
    const rsyncCmd = `${this.rsyncBin} ${this.rsyncArgs} ${srcPath} ${this.backupDestination}`
    console.debug(chalk.bold(rsyncCmd))
    console.info(chalk.blue(chalk.bold('Running Job: ') + this.backupName))
    this.cmdHelperAsync(rsyncCmd)
  }

  backup() {
    this.rsyncArgs += ` ${this.rsyncExcludes} `.trimEnd()
    this.backupPaths.forEach(backupPath => {
      if (backupPath.startsWith('/')) {
        if (this.compress) {
          this.compressFolder(backupPath)
        } else {
          this.backupFolder(backupPath)
        }
      } else {
        console.error(`Backup path: ${backupPath} does not start with a slash /. Passing.`)
      }
    })
  }
}
