const xcode = require('xcode');
const fs = require('fs');
const path = require('path');

const projectPath = path.join(__dirname, 'ios', 'MyApp.xcodeproj', 'project.pbxproj');
if (!fs.existsSync(projectPath)) {
    console.error("Project file not found at " + projectPath);
    process.exit(1);
}

const myProj = xcode.project(projectPath);

myProj.parseSync();

const mainGroup = myProj.getFirstProject().firstProject.mainGroup;

const filesToAdd = [
    'MyApp/AddMemoryIntent.swift',
    'MyApp/MemoryModule.swift',
    'MyApp/MemoryModule.m',
    'MyApp-Bridging-Header.h'
];

filesToAdd.forEach(fileRelPath => {
    const fileName = path.basename(fileRelPath);
    if (!myProj.hasFile(fileRelPath)) {
        myProj.addSourceFile(fileRelPath, null, mainGroup);
        console.log("-> Registered: " + fileRelPath);
    } else {
        console.log("-> Already exists: " + fileRelPath);
    }
});

// Pastikan Bridging Header terpasang di Build Settings
const configurations = myProj.pbxXCBuildConfigurationSection();
for (const key in configurations) {
    if (typeof configurations[key].buildSettings !== 'undefined') {
        const buildSettings = configurations[key].buildSettings;
        buildSettings['SWIFT_OBJC_BRIDGING_HEADER'] = '"MyApp-Bridging-Header.h"';
        buildSettings['SWIFT_VERSION'] = '5.0';
        buildSettings['CLANG_ENABLE_MODULES'] = 'YES';
    }
}

fs.writeFileSync(projectPath, myProj.writeSync());
console.log("FINISH: Semua file native dan konfigurasi Xcode telah disinkronkan!");
