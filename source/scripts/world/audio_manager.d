module world.audio_manager;

import raylib;

import std.stdio;
import std.file;
import std.process;
import std.path;

string optionsFilePath = "options.ini";

enum AudioTypes {
    MUSIC,
    SFX,
    AMBIENT,
    VOX
}

enum AudioVolumes {
    MUSIC_VOLUME = 0.5,
    SFX_VOLUME = 0.5,
    AMBIENT_VOLUME = 0.5,
    VOX_VOLUME = 0.5
}

// implement class
class AudioManager {
    private static AudioManager instance;

    // define variables
    private float musicVolume = AudioVolumes.MUSIC_VOLUME;
    private float sfxVolume = AudioVolumes.SFX_VOLUME;
    private float ambientVolume = AudioVolumes.AMBIENT_VOLUME;
    private float voxVolume = AudioVolumes.VOX_VOLUME;

    // play audio of a specific type
    void playAudio(AudioTypes type) {
        switch (type) {
            case AudioTypes.MUSIC:
                // Play music with volume
                SetMusicVolume(musicVolume);
                break;
            case AudioTypes.SFX:
                // Play sound effect with volume
                SetSoundVolume(sfxVolume);
                break;
            case AudioTypes.AMBIENT:
                // Play ambient sound with volume
                SetSoundVolume(ambientVolume);
                break;
            case AudioTypes.VOX:
                // Play voice sound with volume
                SetSoundVolume(voxVolume);
                break;
        }
    }

    // stop audio of a specific type
    void stopAudio(AudioTypes type) {


        switch (type) {
            case AudioTypes.MUSIC:

                break;
            case AudioTypes.SFX:

                break;
            case AudioTypes.AMBIENT:

                break;
            case AudioTypes.VOX:

                break;
        }
    }

    // init audio settings
    void initAudioSettings() {
        // Load options from file if it exists
        if (fileExists(optionsFilePath)) {
            loadOptions();
        } else {
            // Set default values if options file does not exist
            musicVolume = AudioVolumes.MUSIC_VOLUME;
            sfxVolume = AudioVolumes.SFX_VOLUME;
            ambientVolume = AudioVolumes.AMBIENT_VOLUME;
            voxVolume = AudioVolumes.VOX_VOLUME;
        }
    }

    // load options from file
    void loadOptions() {
        if (!fileExists(optionsFilePath)) {
            writeln("Options file not found, creating default options.ini");
            saveOptions(); // Create default options file
            return;
        }

        auto optionsFile = File(optionsFilePath, "r");
        string[] lines = optionsFile.byLine.array();
        foreach (line; lines) {
            if (line.startsWith("musicVolume =")) {
                musicVolume = to!float(line[13..$]);
            } else if (line.startsWith("sfxVolume =")) {
                sfxVolume = to!float(line[11..$]);
            } else if (line.startsWith("ambientVolume =")) {
                ambientVolume = to!float(line[15..$]);
            } else if (line.startsWith("voxVolume =")) {
                voxVolume = to!float(line[11..$]);
            }
        }
        optionsFile.close();
    }

    // save options to file
    void saveOptions() {
        auto optionsFile = File(optionsFilePath, "w");
        optionsFile.writeln("musicVolume = ", musicVolume);
        optionsFile.writeln("sfxVolume = ", sfxVolume);
        optionsFile.writeln("ambientVolume = ", ambientVolume);
        optionsFile.writeln("voxVolume = ", voxVolume);
        optionsFile.close();
    }
}