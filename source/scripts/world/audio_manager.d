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
    private float currentMusicVolume = 1.0f; // Track current music volume
    
    // For music fade effects
    private bool isFadingOut = false;
    private float fadeOutDuration = 0.0f;
    private float fadeOutTimer = 0.0f;
    private float originalVolume = 1.0f;
    private string pendingMusicPath = "";
    private float pendingMusicVolume = -1.0f;
    private bool pendingMusicLoop = true;
    
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
    void update(float deltaTime = 0.0f) {
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
        
        // Handle music fade out
        if (isFadingOut && isMusicPlaying && currentMusic.ctxData !is null) {
            fadeOutTimer += deltaTime;
            
            if (fadeOutTimer >= fadeOutDuration) {
                // Fade complete, stop current music
                StopMusicStream(currentMusic);
                isFadingOut = false;
                
                // Play pending music if specified
                if (pendingMusicPath != "") {
                    playMusic(pendingMusicPath, pendingMusicVolume, pendingMusicLoop);
                    pendingMusicPath = "";
                }
            } else {
                // Calculate and apply fade volume
                float fadeRatio = fadeOutTimer / fadeOutDuration;
                float currentFadeVolume = originalVolume * (1.0f - fadeRatio);
                SetMusicVolume(currentMusic, currentFadeVolume);
                currentMusicVolume = currentFadeVolume; // Update the tracked volume
            }
        }
    }
    
    /**
     * Play a sound with volume based on settings
     * 
     * Params:
     *   filePath = Path to the sound file
     *   audioType = Type of audio (SFX, MUSIC, VOX, AMBIENCE)
     *   overrideVolume = Optional volume override (0.0 to 1.0). If -1.0f, uses category volume.
     *   loop = Whether to loop the sound (for music and ambience)
     *   
     * Returns: Success flag
     */
    bool playSound(string filePath, AudioType audioType, float overrideVolume = -1.0f, bool loop = false) {
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
        
        float baseVolume;
        // Use overrideVolume if provided and valid, otherwise use category volume from audioSettings
        if (overrideVolume >= 0.0f && overrideVolume <= 1.0f) {
            baseVolume = overrideVolume;
        } else {
            switch (audioType) {
                case AudioType.SFX:
                    baseVolume = audioSettings.sfxVolume;
                    break;
                case AudioType.MUSIC:
                    baseVolume = audioSettings.musicVolume;
                    break;
                case AudioType.VOX:
                    baseVolume = audioSettings.voxVolume;
                    break;
                case AudioType.AMBIENCE:
                    baseVolume = audioSettings.ambienceVolume;
                    break;
                default: // Should not happen
                    baseVolume = 1.0f; 
                    break;
            }
        }
        
        // Calculate final volume by applying master volume
        float finalVolume = baseVolume * audioSettings.masterVolume;
        
        // Clamp final volume between 0.0 and 1.0
        if (finalVolume < 0.0f) finalVolume = 0.0f;
        if (finalVolume > 1.0f) finalVolume = 1.0f;
        
        // Use MemoryManager to load and cache the sound
        if (audioType == AudioType.MUSIC) {
            // Stop any currently playing music first
            if (isMusicPlaying && currentMusic.ctxData != null) {
                StopMusicStream(currentMusic);
                // Unload previous music if you want to free memory immediately,
                // but MemoryManager should handle caching.
                // memoryManager.unloadMusic(currentMusic); // Optional, depends on MemoryManager strategy
            }
            
            Music music = memoryManager.loadMusic(filePath);
            if (music.ctxData == null) {
                writeln("Failed to load music: ", filePath);
                return false;
            }
            
            // Store the current music for later updates
            currentMusic = music;
            isMusicPlaying = true;
            currentMusicVolume = finalVolume; // Store the current volume
            
            SetMusicVolume(music, finalVolume); // Use calculated finalVolume
            currentMusic.looping = loop; // Set looping before playing for Raylib 5.0+

            PlayMusicStream(music);
            // For non-looping music that should play once, UpdateMusicStream might be needed
            // immediately after PlayMusicStream if it doesn't start otherwise.
            // However, typical usage is to call UpdateMusicStream in the game loop;
            
            writeln("Started playing music: ", filePath, " with volume ", finalVolume);
            return true;
        } else {
            Sound sound = memoryManager.loadSound(filePath);
            if (sound.frameCount <= 0) {
                writeln("Failed to load sound: ", filePath);
                return false;
            }
            SetSoundVolume(sound, finalVolume); // Use calculated finalVolume
            PlaySound(sound);
            // Note: IsSoundPlaying(sound) might return false immediately if the sound is very short.
            // For longer sounds, it's a good check.
            return true; // Assume success if PlaySound is called.
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

    /**
     * Updates the volume of the currently playing music stream based on current audio settings.
     */
    public void updateLiveMusicVolume() {
        if (isMusicPlaying && currentMusic.ctxData != null && audioSettings !is null) {
            float baseMusicVol = audioSettings.musicVolume; // From settings (0.0-1.0)
            float masterVol = audioSettings.masterVolume;   // From settings (0.0-1.0)
            
            float finalCombinedVolume = baseMusicVol * masterVol;
            
            // Clamp finalCombinedVolume
            if (finalCombinedVolume < 0.0f) finalCombinedVolume = 0.0f;
            if (finalCombinedVolume > 1.0f) finalCombinedVolume = 1.0f;
            
            SetMusicVolume(currentMusic, finalCombinedVolume);
            currentMusicVolume = finalCombinedVolume; // Update tracked volume
            // writeln("AudioManager: Live updated current music volume to: ", finalCombinedVolume); // Optional: for debugging
        }
    }
    
    /**
     * Start fading out the current music
     * 
     * Params:
     *   duration = Fade-out duration in seconds
     *   nextMusicPath = Music to play after fade completes (optional)
     *   nextMusicVolume = Volume for the next music (optional)
     *   nextMusicLoop = Whether to loop the next music (optional)
     */
    void fadeOutMusic(float duration, string nextMusicPath = "", float nextMusicVolume = -1.0f, bool nextMusicLoop = true) {
        if (!isMusicPlaying || currentMusic.ctxData is null) {
            // If no music is playing, just play the next music immediately
            if (nextMusicPath != "") {
                playMusic(nextMusicPath, nextMusicVolume, nextMusicLoop);
            }
            return;
        }
        
        // Save current volume as the starting point for the fade
        originalVolume = GetMusicVolume(currentMusic);
        
        // Setup fade parameters
        isFadingOut = true;
        fadeOutDuration = duration;
        fadeOutTimer = 0.0f;
        
        // Store pending music to play after fade completes
        pendingMusicPath = nextMusicPath;
        pendingMusicVolume = nextMusicVolume;
        pendingMusicLoop = nextMusicLoop;
    }

    /**
     * Get the current volume of the playing music
     * 
     * Returns: The current volume of the music (0.0 to 1.0)
     */
    float GetMusicVolume(Music music) {
        // We don't need to use the music parameter since we're tracking volume internally
        return currentMusicVolume;
    }
}