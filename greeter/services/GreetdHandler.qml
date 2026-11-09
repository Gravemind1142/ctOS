pragma Singleton

import Quickshell
import Quickshell.Services.Greetd
import QtQuick

import qs.greeter.services
import qs.common

Singleton {
    id: handler

    signal ready
    signal success
    signal failed

    Logger {
        id: logger
        name: "Greetd"
    }

    Connections {
        id: connection
        target: Greetd

        function onAuthMessage(message) {
            // requesting password
            logger.info("Credentials requested.");
            handler.ready();
        }

        function onAuthFailure(message) {
            // password is wrong
            logger.info("Authentication failed.");
            handler.failed();
        }

        function onReadyToLaunch() {
            // password is correct
            logger.info("Authentication success.");
            handler.success();
        }

        function onLaunched() {
            logger.info("Session accepted by greetd.");
        }

        function onError(error) {
            if (!handler._launching) {
                // non-fatal, e.g. greetd answers the automatic cancel_session after a
                // wrong password with "no session under configuration"
                logger.warn(`Greetd error (ignored): ${error}`);
                return;
            }

            // start_session rejected; without this the greeter hangs forever.
            // critical() quits the greeter, greetd then restarts it at the login screen.
            logger.critical(`Greetd error while launching: ${error}`);
        }
    }

    Connections {
        target: SessionManager

        function onActiveUserChanged() {
            if (Greetd.state === GreetdState.Authenticating) {
                logger.info(`User changed, cancelling active session.`);
                Greetd.cancelSession();
            }

            handler.start();
        }
    }

    function start() {
        sessionStarter.start();
    }

    Timer {
        id: sessionStarter
        interval: 200
        repeat: true
        onTriggered: {
            // make sure socket ready for new session
            // authenticating(1) -> inactive (0)
            if (Greetd.state !== GreetdState.Inactive) {
                return;
            }

            logger.info(`Created session (user:${SessionManager.activeUser.uid}:${SessionManager.activeUser.username})`);
            Greetd.createSession(SessionManager.activeUser.username);

            sessionStarter.stop();
        }
    }

    function respond(password) {
        if (Greetd.available) {
            Greetd.respond(password);
        } else {
            logger.debug("Failed to respond, Not available.");
        }
    }

    property bool _launching: false

    function finish() {
        const launchCommand = SessionManager.getLaunchCommand();
        const exitCommand = SessionManager.getExitCommand();

        if (!launchCommand.length) {
            logger.critical(`No launch command for desktop '${SessionManager.activeDesktop?.name ?? "<none>"}'`);
            return;
        }

        const launchEnv = SessionManager.getLaunchEnvironment();

        logger.info(`Launching: ${launchCommand.join(" ")}`);
        logger.info(`Environment: ${launchEnv.join(" ")}`);
        logger.info(`Exiting Greeter: ${exitCommand.join(" ") || "<none>"}`);

        handler._launching = true;
        Greetd.launch(launchCommand, launchEnv);

        if (exitCommand.length) {
            Quickshell.execDetached(exitCommand);
        }
    }
}
