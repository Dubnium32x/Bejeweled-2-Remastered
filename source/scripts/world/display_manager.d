module world.display_manager;

import raylib;

import std.stdio;
import std.file;
import std.json;
import std.path;

import world.game_manager;

// ---- ENUMS ----
enum Resolution { // keep to 16:9
    RES_640x360,
    RES_800x450,
    RES_1280x720,
    RES_1600x900,
    RES_1920x1080,
    RES_2560x1440,
    RES_3840x2160
}

// ---- CLASS ----
class DisplayManager {
    // Singleton instance
    static DisplayManager instance;
    static DisplayManager getInstance() {
        if (instance is null) {
            instance = new DisplayManager();
        }
        return instance;
    }

    Resolution resolution;
    bool isFullscreen = false;
    int frameRate = 60;

    void setResolution(Resolution res) {
        resolution = res;
        applySettings();
    }

    void toggleFullscreen() {
        if (IsWindowFullscreen()) {
            // Exit fullscreen
            
            isFullscreen = false;
        } else {
            // Enter fullscreen
            ToggleFullscreen();
            isFullscreen = true;
        }
        applySettings();
    }

    void setFrameRate(int fps) {
        SetTargetFPS(fps);
        frameRate = fps;
    }

    void applySettings() {
        final switch (resolution) {
            case Resolution.RES_640x360:
                SetWindowSize(640, 360);
                break;
            case Resolution.RES_800x450:
                SetWindowSize(800, 450);
                break;
            case Resolution.RES_1280x720:
                SetWindowSize(1280, 720);
                break;
            case Resolution.RES_1600x900:
                SetWindowSize(1600, 900);
                break;
            case Resolution.RES_1920x1080:
                SetWindowSize(1920, 1080);
                break;
            case Resolution.RES_2560x1440:
                SetWindowSize(2560, 1440);
                break;
            case Resolution.RES_3840x2160:
                SetWindowSize(3840, 2160);
                break;
        }
        // Fullscreen state is handled in toggleFullscreen
    }
}