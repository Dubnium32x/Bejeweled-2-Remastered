module world.audio_manager;

import raylib;

import std.stdio;
import std.file;
import std.json;
import std.path;
import std.process;
import std.string;
import std.algorithm;

import world.audio_settings;
import world.memory_manager;

// ---- ENUMS ----
enum AudioType {
    MUSIC,
    SFX,
    VOX,
    AMBIENCE
}

int[] audioChannels = [0, 0, 0, 0, 0, 0]; // 0: MUSIC, 1: VOX, 2: AMBIENCE, 3 to 5: SFX

// ---- CLASS ----
class AudioManager {
    // Singleton instance
    private __gshared AudioManager instance;
    // Audio settings
    AudioSettings audioSettings;
    // Memory manager reference
    private MemoryManager memoryManager;

    // Add a variable to track the currently playing music
    private Music currentMusic;
    private bool isMusicPlaying = false;
    
    this() {
        audioSettings = AudioSettings.getInstance();
        memoryManager = MemoryManager.instance();
    }
    
    // Static method to get the singleton instance
    static AudioManager getInstance() {
        if (instance is null) {
            synchronized {
                if (instance is null) {
                    instance = new AudioManager();
                }
            }
        }
        return instance;
    }

    // Initialize audio settings
    void initialize() {
        if (audioSettings.state == AudioSettingsState.INITIALIZED) {
            writeln("AudioSettings already initialized.");
            return;
        }

        // Load settings from a configuration file if it exists
        AudioSettings.getInstance().loadSettings();
        audioSettings.state = AudioSettingsState.INITIALIZED;
        writeln("AudioSettings initialized successfully.");

        if (!IsAudioDeviceReady()) {
            writeln("Failed to initialize audio device.");
            return;
        }
        writeln("Audio device initialized successfully.");
    }

    // Optimize music update with buffer management and better error handling
    void update() {
        // Update audio settings if needed
        if (audioSettings.state != AudioSettingsState.INITIALIZED) {
            initialize();
        }
        
        // Update music stream with improved error handling
        if (isMusicPlaying && currentMusic.ctxData != null) {
            try {
                UpdateMusicStream(currentMusic);
                
                // Check if music finished playing (non-looping music)
                if (!IsMusicStreamPlaying(currentMusic)) {
                    isMusicPlaying = false;
                }
            } catch (Exception e) {
                writeln("Error updating music stream: ", e.msg);
                isMusicPlaying = false;
            }
        }
    }
    
    /**
     * Play a sound with volume based on settings
     * 
     * Params:
     *   filePath = Path to the sound file
     *   audioType = Type of audio (SFX, MUSIC, VOX, AMBIENCE)
     *   volume = Optional volume override (0.0 to 1.0)
     *   loop = Whether to loop the sound (for music and ambience)
     *   
     * Returns: Success flag
     */
    bool playSound(string filePath, AudioType audioType, float volume = -1.0f, bool loop = false) {
        // Check if the requested audio type is enabled
        final switch (audioType) {
            case AudioType.SFX:
                if (!audioSettings.isSFXEnabled) return false;
                break;
            case AudioType.MUSIC:
                if (!audioSettings.isMusicEnabled) return false;
                break;
            case AudioType.VOX:
                if (!audioSettings.isVoxEnabled) return false;
                break;
            case AudioType.AMBIENCE:
                if (!audioSettings.isAmbienceEnabled) return false;
                break;
        }
        
        if (!exists(filePath)) {
            writeln("Sound file does not exist: ", filePath);
            return false;
        }
        
        // Use volume from settings if not specified
        if (volume < 0) {
            final switch (audioType) {
                case AudioType.SFX:
                    volume = audioSettings.sfxVolume;
                    break;
                case AudioType.MUSIC:
                    volume = audioSettings.musicVolume;
                    break;
                case AudioType.VOX:
                    volume = audioSettings.voxVolume;
                    break;
                case AudioType.AMBIENCE:
                    volume = audioSettings.ambienceVolume;
                    break;
            }
        }
        
        // Scale volume based on settings
        float scaledVolume = getScaledVolume(volume, audioType);
        
        // Use MemoryManager to load and cache the sound
        if (audioType == AudioType.MUSIC) {
            // Stop any currently playing music first
            if (isMusicPlaying && currentMusic.ctxData != null) {
                StopMusicStream(currentMusic);
            }
            
            Music music = memoryManager.loadMusic(filePath);
            if (music.ctxData == null) {
                writeln("Failed to load music: ", filePath);
                return false;
            }
            
            // Store the current music for later updates
            currentMusic = music;
            isMusicPlaying = true;
            
            SetMusicVolume(music, scaledVolume);
            if (loop) {
                PlayMusicStream(music);
            } else {
                UpdateMusicStream(music);
                PlayMusicStream(music);
            }
            
            writeln("Started playing music: ", filePath, " with volume ", scaledVolume);
            return true;
        } else {
            Sound sound = memoryManager.loadSound(filePath);
            if (sound.frameCount <= 0) {
                writeln("Failed to load sound: ", filePath);
                return false;
            }
            SetSoundVolume(sound, scaledVolume);
            PlaySound(sound);
            return IsSoundPlaying(sound);
        }
    }
    
    /**
     * Play a music track with volume based on settings
     * 
     * Params:
     *   filePath = Path to the music file
     *   volume = Optional volume override (0.0 to 1.0)
     *   loop = Whether to loop the music
     *   
     * Returns: Success flag
     */
    bool playMusic(string filePath, float volume = -1.0f, bool loop = true) {
        return playSound(filePath, AudioType.MUSIC, volume, loop);
    }
    
    /**
     * Play an SFX with volume based on settings
     * 
     * Params:
     *   filePath = Path to the SFX file
     *   volume = Optional volume override (0.0 to 1.0)
     *   
     * Returns: Success flag
     */
    bool playSFX(string filePath, float volume = -1.0f) {
        return playSound(filePath, AudioType.SFX, volume);
    }
    
    /**
     * Play a voice clip with volume based on settings
     * 
     * Params:
     *   filePath = Path to the voice file
     *   volume = Optional volume override (0.0 to 1.0)
     *   
     * Returns: Success flag
     */
    bool playVOX(string filePath, float volume = -1.0f) {
        return playSound(filePath, AudioType.VOX, volume);
    }
    
    /**
     * Play an ambience track with volume based on settings
     * 
     * Params:
     *   filePath = Path to the ambience file
     *   volume = Optional volume override (0.0 to 1.0)
     *   loop = Whether to loop the ambience
     *   
     * Returns: Success flag
     */
    bool playAmbience(string filePath, float volume = -1.0f, bool loop = true) {
        return playSound(filePath, AudioType.AMBIENCE, volume, loop);
    }
    
    /**
     * Preload sounds in the background to avoid loading hitches during gameplay
     * 
     * Params:
     *   soundPaths = Paths to sound files to preload
     *   musicPaths = Paths to music files to preload
     */
    void preloadAudio(string[] soundPaths, string[] musicPaths = []) {
        // Use the MemoryManager to preload resources
        memoryManager.preloadResources([], soundPaths, musicPaths);
    }
    
    /**
     * Legacy method for backward compatibility
     * Simply forwards to the appropriate playSFX method
     */
    void loadSound(string filePath, AudioType audioType) {
        switch (audioType) {
            case AudioType.MUSIC:
                playMusic(filePath);
                break;
            case AudioType.VOX:
                playVOX(filePath);
                break;
            case AudioType.AMBIENCE:
                playAmbience(filePath);
                break;
            case AudioType.SFX:
            default:
                playSFX(filePath);
                break;
        }
    }

    // Improved volume handling with proper scaling and clamping
    private float getScaledVolume(float rawVolume, AudioType type) {
        // Apply master volume scaling
        float scaledVolume = rawVolume * audioSettings.masterVolume;
        
        // Apply type-specific volume scaling
        final switch (type) {
            case AudioType.SFX:
                scaledVolume *= audioSettings.sfxVolume;
                break;
            case AudioType.MUSIC:
                scaledVolume *= audioSettings.musicVolume;
                break;
            case AudioType.VOX:
                scaledVolume *= audioSettings.voxVolume;
                break;
            case AudioType.AMBIENCE:
                scaledVolume *= audioSettings.ambienceVolume;
                break;
        }
        
        // Clamp volume between 0.0 and 1.0
        if (scaledVolume < 0.0f) scaledVolume = 0.0f;
        if (scaledVolume > 1.0f) scaledVolume = 1.0f;
        
        return scaledVolume;
    }
}