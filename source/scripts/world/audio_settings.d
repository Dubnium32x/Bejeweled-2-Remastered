module world.audio_settings;

import raylib;

import std.stdio;
import std.file;
import std.json;
import std.path;
import std.process;
import std.string;
import std.algorithm;
import std.conv : to;

// ---- ENUMS ----
enum AudioSettingsState {
    UNINITIALIZED,
    INITIALIZED
}

// ---- CLASS ----
class AudioSettings {
    // Singleton instance
    private __gshared AudioSettings instance;

    // Current state of the settings
    AudioSettingsState state;

    // Audio settings
    bool isMusicEnabled;
    bool isSFXEnabled;
    bool isVoxEnabled;
    bool isAmbienceEnabled;
    float musicVolume;
    float sfxVolume;
    float voxVolume;
    float ambienceVolume;

    this() {
        instance = this;
        state = AudioSettingsState.UNINITIALIZED;
        isMusicEnabled = true; // Default music setting
        isSFXEnabled = true; // Default SFX setting
        isVoxEnabled = true; // Default VOX setting
        isAmbienceEnabled = true; // Default Ambience setting
        musicVolume = 0.5; // Default music volume
        sfxVolume = 0.5; // Default SFX volume
        voxVolume = 0.5; // Default VOX volume
        ambienceVolume = 0.5; // Default Ambience volume
    }

    static AudioSettings getInstance() {
        if (instance is null) {
            synchronized {
                if (instance is null) {
                    instance = new AudioSettings();
                }
            }
        }
        return instance;
    }

    void initialize() {
        if (state == AudioSettingsState.INITIALIZED) {
            writeln("AudioSettings already initialized.");
            return;
        }

        // Load settings from a configuration file if it exists
        string configFilePath = "config/audio_settings.json";
        if (exists(configFilePath)) {
            try {
                auto jsonData = parseJSON(readText(configFilePath));
                if ("isMusicEnabled" in jsonData) isMusicEnabled = jsonData["isMusicEnabled"].boolean;
                if ("isSFXEnabled" in jsonData) isSFXEnabled = jsonData["isSFXEnabled"].boolean;
                if ("isVoxEnabled" in jsonData) isVoxEnabled = jsonData["isVoxEnabled"].boolean;
                if ("isAmbienceEnabled" in jsonData) isAmbienceEnabled = jsonData["isAmbienceEnabled"].boolean;
                if ("musicVolume" in jsonData) musicVolume = jsonData["musicVolume"].floating;
                if ("sfxVolume" in jsonData) sfxVolume = jsonData["sfxVolume"].floating;
                if ("voxVolume" in jsonData) voxVolume = jsonData["voxVolume"].floating;
                if ("ambienceVolume" in jsonData) ambienceVolume = jsonData["ambienceVolume"].floating;
            } 
            catch (Exception e) {
                writeln("Error loading audio settings: ", e.msg);
            }
        }
        else {
            writeln("No config file found, using default settings.");
        }
        state = AudioSettingsState.INITIALIZED;
    }

    void saveSettings() {
        // Create the config directory if it doesn't exist
        string configDir = "config";
        if (!exists(configDir)) {
            try {
                mkdir(configDir);
            } catch (Exception e) {
                writeln("Error creating config directory: ", e.msg);
                return;
            }
        }

        // Prepare JSON data using JSONValue
        JSONValue jsonData = JSONValue();
        jsonData["isMusicEnabled"] = isMusicEnabled;
        jsonData["isSFXEnabled"] = isSFXEnabled;
        jsonData["isVoxEnabled"] = isVoxEnabled;
        jsonData["isAmbienceEnabled"] = isAmbienceEnabled;
        jsonData["musicVolume"] = musicVolume;
        jsonData["sfxVolume"] = sfxVolume;
        jsonData["voxVolume"] = voxVolume;
        jsonData["ambienceVolume"] = ambienceVolume;

        // Write to the config file
        string configFilePath = buildPath(configDir, "audio_settings.json");
        try {
            std.file.write(configFilePath, jsonData.toString());
            writeln("Audio settings saved successfully.");
        } catch (Exception e) {
            writeln("Error saving audio settings: ", e.msg);
        }
    }

    void loadSettings() {
        // Load settings from a configuration file if it exists
        string configFilePath = "config/audio_settings.json";
        if (exists(configFilePath)) {
            try {
                auto jsonData = parseJSON(readText(configFilePath));
                
                // Use proper JSON value access with default fallbacks
                isMusicEnabled = "isMusicEnabled" in jsonData ? jsonData["isMusicEnabled"].boolean : true;
                isSFXEnabled = "isSFXEnabled" in jsonData ? jsonData["isSFXEnabled"].boolean : true;
                isVoxEnabled = "isVoxEnabled" in jsonData ? jsonData["isVoxEnabled"].boolean : true;
                isAmbienceEnabled = "isAmbienceEnabled" in jsonData ? jsonData["isAmbienceEnabled"].boolean : true;
                musicVolume = "musicVolume" in jsonData ? jsonData["musicVolume"].floating : 0.5f;
                sfxVolume = "sfxVolume" in jsonData ? jsonData["sfxVolume"].floating : 0.5f;
                voxVolume = "voxVolume" in jsonData ? jsonData["voxVolume"].floating : 0.5f;
                ambienceVolume = "ambienceVolume" in jsonData ? jsonData["ambienceVolume"].floating : 0.5f;
            } 
            catch (Exception e) {
                writeln("Error loading audio settings: ", e.msg);
            }
        }
        else {
            writeln("No config file found, using default settings.");
            setDefaultSettings();
        }
    }

    void setDefaultSettings() {
        isMusicEnabled = true; // Default music setting
        isSFXEnabled = true; // Default SFX setting
        isVoxEnabled = true; // Default VOX setting
        isAmbienceEnabled = true; // Default Ambience setting
        musicVolume = 0.5; // Default music volume
        sfxVolume = 0.5; // Default SFX volume
        voxVolume = 0.5; // Default VOX volume
        ambienceVolume = 0.5; // Default Ambience volume
    }

    void resetSettings() {
        setDefaultSettings();
        saveSettings();
    }
}
