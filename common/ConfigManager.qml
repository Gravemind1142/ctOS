import QtQuick
import Quickshell.Io
import qs.common

Item {
    id: config

    required property string path
    required property JsonAdapter adapter

    property bool writeEnabled: true

    // reload when the file is edited externally
    property bool watchChanges: false

    readonly property bool _canWrite: config.writeEnabled && !fileView.path.startsWith("/etc")

    // A watch set up before the file exists never fires, so pause it while a
    // missing file is created and re-arm it once the file is on disk.
    property bool _watchArmed: true

    Logger {
        id: logger
        name: "ConfigManager"
    }

    FileView {
        id: fileView

        // qmllint disable missing-type
        adapter: config.adapter
        path: config.path

        watchChanges: config.watchChanges && config._watchArmed
        onFileChanged: {
            logger.info(`Reloading changed file: ${fileView.path}`);
            reload();
        }

        onSaved: config._watchArmed = true

        // Only persist real changes. Writing on adapter assignment would
        // overwrite the file with default values before it has been read.
        onAdapterUpdated: config._canWrite ? writeAdapter() : () => {}

        onLoadFailed: function (error) {
            if (error !== FileViewError.FileNotFound) {
                return;
            }

            if (config._canWrite) {
                logger.info(`Creating missing file: ${fileView.path}`);
                config._watchArmed = false;
                // writing from inside the failed load drops the operation, defer it
                Qt.callLater(fileView.writeAdapter);
                return;
            }

            logger.critical(`Missing config file: ${fileView.path}`);
        }

        onSaveFailed: function (error) {
            logger.error(`Failed to save ${fileView.path} (error ${error})`);
        }
    }
}
