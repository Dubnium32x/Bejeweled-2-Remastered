module world.audio_manager;

import raylib;

import std.stdio;
import std.file;
import std.json;
import std.path;
import std.process;
import std.string;

import world.game_manager;

// ---- ENUMS ----
enum AudioType {
    MUSIC,
    SFX,
    VOX,
    AMBIENCE
}

enum AudioState {
    PLAYING,
    PAUSED,
    STOPPED
}

enum AudioLoop {
    ONCE,
    LOOP
}

enum AudioVolumes {
    MUSIC_VOLUME = 0.5,
    SFX_VOLUME = 0.5,
    VOX_VOLUME = 0.5,
    AMBIENCE_VOLUME = 0.5
}

Music musicTrack;

// Remove individual soundEffect1..8 and use arrays
Sound[8] soundEffects;
bool[8] soundInUse;

// ---- CLASS ----
class AudioManager {
    AudioType audioType;
    AudioState audioState;
    AudioLoop audioLoop;
    // Add volume fields as class members
    float musicVolume;
    float sfxVolume;
    float voxVolume;
    float ambienceVolume;
    
    // Find the next available sound slot
    int nextAvailableSoundEffect() {
        foreach (int i, used; soundInUse) {
            if (!used) return i;
        }

        // If all are in use, return null or throw an error
        throw new Exception("No available sound effect slots.");
    }

    // Mark a slot as used
    void setSoundEffect(int index, Sound sfx) {
        soundEffects[index] = sfx;
        soundInUse[index] = true;
    }

    // Mark a slot as unused (e.g., after unloading)
    void freeSoundEffect(int index) {
        UnloadSound(soundEffects[index]);
        soundInUse[index] = false;
    }

    this() {
        // Initialize volumes with default values
        musicVolume = AudioVolumes.MUSIC_VOLUME;
        sfxVolume = AudioVolumes.SFX_VOLUME;
        voxVolume = AudioVolumes.VOX_VOLUME;
        ambienceVolume = AudioVolumes.AMBIENCE_VOLUME;
        // Initialize all slots as unused
        soundInUse[] = false;
    }

    /*
    ---- NOTE ----
    This part of the code is responsible for setting the volume of different audio types.
    I wish I knew what to do about the `auto` keyword here, but it seems to be a placeholder for the actual type.
    Whether that be Music, Sound, or any other audio type. Doesn't seem to be a way to specify that in D.
    */
    void setVolume(AudioType audioType, void* sfx, float volume) {
        switch (audioType) {
            case AudioType.MUSIC:
                musicVolume = volume;
                SetMusicVolume(musicTrack, musicVolume);
                break;
            case AudioType.SFX:
                sfxVolume = volume;
                // Cast sfx to Sound* and set its volume
                if (sfx !is null) {
                    SetSoundVolume(*cast(Sound*)sfx, sfxVolume);
                }
                break;
            case AudioType.VOX:
                voxVolume = volume;
                // Assuming there's a function to set voice volume
                SetSoundVolume(*cast(Sound*)sfx, voxVolume);
                break;
            case AudioType.AMBIENCE:
                ambienceVolume = volume;
                // Assuming there's a function to set ambience volume
                SetSoundVolume(*cast(Sound*)sfx, ambienceVolume);
                break;
            default:
                throw new Exception("Invalid AudioType specified.");
        }
    }
}