/* eslint-disable space-before-function-paren */
/* eslint-disable require-jsdoc */
import process from 'process'
import BackupManager from './backupManager.js'

const backupObj = new BackupManager(process.argv[2])
backupObj.backup()
