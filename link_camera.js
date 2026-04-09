const xcode = require('xcode');
const fs = require('fs');
const path = require('path');

const projectPath = path.join(__dirname, 'ios', 'MyApp.xcodeproj', 'project.pbxproj');
const myProj = xcode.project(projectPath);

myProj.parseSync();

const mainGroup = myProj.getFirstProject().firstProject.mainGroup;

const newFiles = [
    'MyApp/DualCameraView.swift',
    'MyApp/DualCameraViewManager.swift',
    'MyApp/DualCameraViewManager.m'
];

newFiles.forEach(f => {
    if (!myProj.hasFile(f)) {
        myProj.addSourceFile(f, null, mainGroup);
        console.log("-> Added: " + f);
    }
});

myProj.addFramework('AVFoundation.framework', { 'link': true });

fs.writeFileSync(projectPath, myProj.writeSync());
console.log("SUKSES: Fitur Dual Camera Native telah didaftarkan ke Xcode!");
