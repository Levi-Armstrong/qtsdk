/****************************************************************************
**
** Copyright (C) 2015 The Qt Company Ltd.
** Contact: http://www.qt.io/licensing/
**
** This file is part of the release tools of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL21$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see http://www.qt.io/terms-conditions. For further
** information use the contact form at http://www.qt.io/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 2.1 or version 3 as published by the Free
** Software Foundation and appearing in the file LICENSE.LGPLv21 and
** LICENSE.LGPLv3 included in the packaging of this file. Please review the
** following information to ensure the GNU Lesser General Public License
** requirements will be met: https://www.gnu.org/licenses/lgpl.html and
** http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html.
**
** As a special exception, The Qt Company gives you certain additional
** rights. These rights are described in The Qt Company LGPL Exception
** version 1.1, included in the file LGPL_EXCEPTION.txt in this package.
**
** $QT_END_LICENSE$
**
****************************************************************************/

// constructor
function Component()
{
    if (installer.value("os") == "mac") {
        var xcodeVersion = installer.execute("/usr/bin/xcodebuild", new Array("-version"))[0];
        if (xcodeVersion) {
            var version = xcodeVersion.replace( /\D+/g, '');
            if (parseInt(version) >= parseInt(400) && parseInt(version) <= parseInt(500)) {
                QMessageBox["warning"]("XcodeVersionError",
                        qsTr("You need to update Xcode to latest version!"),
                        qsTr("It is recommeneded to have Xcode version greater than 4.0.0 and smaller than 5.0.0 for Qt5.6 compilations with clang."));
            }
        }
        else {
            QMessageBox["warning"]("XcodeError",
                qsTr("Xcode installation not found!"),
                qsTr("You need to install Xcode version 5.0.0. Download Xcode from https://developer.apple.com/xcode\n"));
        }
    }
}

Component.prototype.beginInstallation = function()
{
    installer.setValue(component.name + "_qtpath", "@TargetDir@" + "%TARGET_INSTALL_DIR%");
}

Component.prototype.createOperations = function()
{
    component.createOperations();
    try {
        var qtPath = "@TargetDir@" + "%TARGET_INSTALL_DIR%";
        var qmakeBinary = "@TargetDir@" + "%TARGET_INSTALL_DIR%/bin/qmake";
        addInitQtPatchOperation(component, "mac", qtPath, qmakeBinary, "qt5");

        if (installer.value("SDKToolBinary") == "")
            return;

        component.addOperation("Execute",
                               ["@SDKToolBinary@", "addQt",
                                "--id", component.name,
                                "--name", "Qt %{Qt:Version} clang 64bit",
                                "--type", "Qt4ProjectManager.QtVersion.Desktop",
                                "--qmake", qmakeBinary,
                                "UNDOEXECUTE",
                                "@SDKToolBinary@", "rmQt", "--id", component.name]);

        var kitName = component.name + "_kit";
        component.addOperation("Execute",
                               ["@SDKToolBinary@", "addKit",
                                "--id", kitName,
                                "--name", "Desktop Qt %{Qt:Version} clang 64bit",
                                "--toolchain", "x86-macos-generic-mach_o-64bit",
                                "--qt", component.name,
                                "--debuggerengine", "256", // DebuggerEngineType::LldbEngineType
                                "--devicetype", "Desktop",
                                "UNDOEXECUTE",
                                "@SDKToolBinary@", "rmKit", "--id", kitName]);

        // patch/register docs and examples
        var installationPath = installer.value("TargetDir") + "%TARGET_INSTALL_DIR%";
        print("Register documentation and examples for: " + installationPath);
        patchQtExamplesAndDoc(component, installationPath, "Qt-5.6");

        // patch qt edition
        var qconfigFile = qtPath + "/mkspecs/qconfig.pri";
        component.addOperation("LineReplace", qconfigFile, "QT_EDITION =", "QT_EDITION = OpenSource");
    } catch(e) {
        print(e);
    }
}

//QTBUG-37650
function patchQtAssistant(aComponent, aComponentRootPath, aQtInstallationName)
{
    if (installer.value("os") == "mac") {
        print("Patching qt.conf for Assistant to: " + aComponentRootPath);
        var fileName = aComponentRootPath + "/bin/Assistant.app/Contents/Resources/" + "qt.conf";
        print("qt.conf file: " + fileName);

        aComponent.addOperation("Settings",
            "path=" + fileName,
            "method=add_array_value",
            "key=Paths/Prefix",
            "value=../../..");

        aComponent.addOperation("Settings",
        "path=" + fileName,
        "method=add_array_value",
        "key=Paths/Documentation",
        "value=../../Docs/" + aQtInstallationName);
    }
}
