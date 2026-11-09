import QtQuick
import Quickshell.Io
import qs.common

Item {
    id: config

    required property string path
    required property JsonAdapter adapter

    property bool writeEnabled: true

    readonly property bool _canWrite: config.writeEnabled && !fileView.path.startsWith("/etc")

    Logger {
        id: logger
        name: "ConfigManager"
    }

    FileView {
        id: fileView

        // qmllint disable missing-type
        adapter: config.adapter
        path: config.path

        // Only persist real changes. Writing on adapter assignment would
        // overwrite the file with default values before it has been read.
        onAdapterUpdated: config._canWrite ? writeAdapter() : () => {}

        onLoadFailed: function (error) {
            if (error !== FileViewError.FileNotFound) {
                return;
            }

            if (config._canWrite) {
                logger.info(`Creating missing file: ${fileView.path}`);
                writeAdapter();
                return;
            }

            logger.critical(`Missing config file: ${fileView.path}`);
        }

        onSaveFailed: function (error) {
            logger.error(`Failed to save ${fileView.path} (error ${error})`);
        }
    }
}
