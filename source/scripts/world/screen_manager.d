module world.screen_manager;

import raylib;

import std.stdio;
import std.file;
import std.process;

import world.screen_states;

// Interface for screen management
interface IScreen {
    void load();
    void unload();
    void update();
    void draw();
}

// Manages the current screen state and transitions between screens
class ScreenManager {
    private IScreen currentScreen;
    private ScreenState currentState;

    this() {
        currentState = ScreenState.INIT;
        currentScreen = null;
    }

    void setScreen(IScreen newScreen, ScreenState newState) {
        if (currentScreen !is null) {
            currentScreen.unload();
        }
        currentScreen = newScreen;
        currentState = newState;
        if (currentScreen !is null) {
            currentScreen.load();
        }
    }

    void update() {
        if (currentScreen !is null) {
            currentScreen.update();
        }
    }

    void draw() {
        if (currentScreen !is null) {
            currentScreen.draw();
        }
    }

    ScreenState getCurrentState() {
        return currentState;
    }
}

