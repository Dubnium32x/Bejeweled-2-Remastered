module world.display_manager;

import raylib;

import std.stdio;
import std.file;
import std.process;
import std.path;

// get options.ini
string optionsFilePath = "options.ini";

// Resolution settings... keep to 16:9 aspect ratio for compatibility
int[] ResolutionsX = [640, 800, 1024, 1280, 1600, 1920, 2560, 3840]
int[] ResolutionsY = [360, 450, 576, 720, 900, 1080, 1440, 2160]

int brightness = 100; // Default brightness level (0-100)
int contrast = 100; // Default contrast level (0-100)
int gamma = 100; // Default gamma level (0-100)

enum DisplayModes {
    WINDOWED,
    FULLSCREEN,
    BORDERLESS
}

void printResolutions() {
    writeln("Available Resolutions:");
    for (size_t i = 0; i < ResolutionsX.length; i++) {
        writeln(ResolutionsX[i], "x", ResolutionsY[i]);
    }
}  

void setDisplayMode(DisplayModes mode, int width, int height) {
    switch (mode) {
        case DisplayModes.WINDOWED:
            SetWindowSize(width, height);
            SetWindowState(FLAG_WINDOW_RESIZABLE);
            SetWindowState(FLAG_WINDOW_UNDECORATED); // Remove title bar
            break;
        case DisplayModes.FULLSCREEN:
            SetWindowSize(width, height);
            SetWindowState(FLAG_FULLSCREEN_MODE);
            break;
        case DisplayModes.BORDERLESS:
            SetWindowSize(width, height);
            SetWindowState(FLAG_WINDOW_RESIZABLE);
            SetWindowState(FLAG_WINDOW_UNDECORATED); // Remove title bar
            break;
    }
}

void initDisplaySettings() {

    brightness = 100;
    contrast = 100;
    gamma = 100;

    loadOptions();

    if (fileExists(optionsFilePath)) {
        auto optionsFile = File(optionsFilePath, "r");
        string[] lines = optionsFile.byLine.array();
        foreach (line; lines) {
            if (line.startsWith("brightness =")) {
                brightness = to!int(line[11..$]);
            } else if (line.startsWith("contrast =")) {
                contrast = to!int(line[9..$]);
            } else if (line.startsWith("gamma =")) {
                gamma = to!int(line[6..$]);
            }
            
        }
        optionsFile.close();
    } else {
        loadOptions();
    }
}


void loadOptions() {
    if (!fileExists(optionsFilePath)) {
        writeln("Options file not found, creating default options.ini");
        auto optionsFile = File(optionsFilePath, "w");
        optionsFile.writeln("brightness = 100");
        optionsFile.writeln("contrast = 100");
        optionsFile.writeln("gamma = 100");
        optionsFile.close();
    }
}

void saveOptions() {
    auto optionsFile = File(optionsFilePath, "w");
    optionsFile.writeln("brightness = ", brightness);
    optionsFile.writeln("contrast = ", contrast);
    optionsFile.writeln("gamma = ", gamma);
    optionsFile.close();
}