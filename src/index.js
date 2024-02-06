#!/usr/bin/env node
import process from 'process'
import BackupManager from './backupManager.js'

if (process.argv[2]) {
    const backupObj = new BackupManager(process.argv[2])
    backupObj.backup()
} else {
    console.error('Pass me a yaml file to parse!')
}
