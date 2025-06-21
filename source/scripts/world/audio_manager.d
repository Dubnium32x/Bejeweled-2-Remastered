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
import data; // Add import for accessing game options

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
    private int currentMusicStyle = 2; // 1 = Original, 2 = Arranged (default to Arranged)
    private string currentBaseMusicPath = ""; // Store the base music path without style folder
    
    // For music fade effects
    private bool isFadingOut = false;
    private float fadeOutDuration = 0.0f;
    private float fadeOutTimer = 0.0f;
    private float originalVolume = 1.0f;
    private string pendingMusicPath = "";
    private float pendingMusicVolume = -1.0f;
    private bool pendingMusicLoop = true;
    private float pendingMusicDelay = 0.0f; // Delay before starting pending music
    private float pendingMusicDelayTimer = 0.0f; // Timer for delay
    private bool isPendingMusicDelayed = false; // Whether pending music is in delay phase
    
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
        
        // Update sound queue
        updateSoundQueue(deltaTime);
        
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
                writeln("AudioManager: Music fade complete, stopped current music");
                
                // Check if pending music should be delayed
                if (pendingMusicPath != "" && pendingMusicDelay > 0.0f) {
                    isPendingMusicDelayed = true;
                    pendingMusicDelayTimer = 0.0f;
                    writeln("AudioManager: Starting ", pendingMusicDelay, "s delay before pending music");
                } else if (pendingMusicPath != "") {
                    // No delay, play immediately
                    playMusic(pendingMusicPath, pendingMusicVolume, pendingMusicLoop);
                    writeln("AudioManager: Started pending music: ", pendingMusicPath);
                    pendingMusicPath = "";
                }
            } else {
                // Calculate and apply fade volume
                float fadeRatio = fadeOutTimer / fadeOutDuration;
                float currentFadeVolume = originalVolume * (1.0f - fadeRatio);
                SetMusicVolume(currentMusic, currentFadeVolume);
                currentMusicVolume = currentFadeVolume; // Update the tracked volume
                
                // Debug output every 10% of fade progress
                if (cast(int)(fadeRatio * 10) != cast(int)((fadeRatio - deltaTime / fadeOutDuration) * 10)) {
                    writeln("AudioManager: Music fading... ", cast(int)(fadeRatio * 100), "% complete");
                }
            }
        }
        
        // Handle pending music delay after fade completes
        if (isPendingMusicDelayed) {
            pendingMusicDelayTimer += deltaTime;
            
            if (pendingMusicDelayTimer >= pendingMusicDelay) {
                // Delay complete, play the pending music
                if (pendingMusicPath != "") {
                    playMusic(pendingMusicPath, pendingMusicVolume, pendingMusicLoop);
                    writeln("AudioManager: Started delayed pending music: ", pendingMusicPath);
                    pendingMusicPath = "";
                }
                isPendingMusicDelayed = false;
                pendingMusicDelay = 0.0f;
                pendingMusicDelayTimer = 0.0f;
            }
        }
        
        // Update sound queue timers and play queued sounds
        updateSoundQueue(deltaTime);
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
     *   nextMusicDelay = Delay in seconds before starting the next music (optional)
     */
    void fadeOutMusic(float duration, string nextMusicPath = "", float nextMusicVolume = -1.0f, bool nextMusicLoop = true, float nextMusicDelay = 0.0f) {
        if (!isMusicPlaying || currentMusic.ctxData is null) {
            // If no music is playing, handle delay and then play the next music
            if (nextMusicPath != "" && nextMusicDelay > 0.0f) {
                isPendingMusicDelayed = true;
                pendingMusicDelayTimer = 0.0f;
                pendingMusicDelay = nextMusicDelay;
                pendingMusicPath = nextMusicPath;
                pendingMusicVolume = nextMusicVolume;
                pendingMusicLoop = nextMusicLoop;
            } else if (nextMusicPath != "") {
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
        pendingMusicDelay = nextMusicDelay;
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
    
    /**
     * Set the music style and switch current music if needed
     * 
     * Params:
     *   style = 1 for Original, 2 for Arranged
     */
    void setMusicStyle(int style) {
        if (style != 1 && style != 2) {
            writeln("Invalid music style: ", style, ". Must be 1 (Original) or 2 (Arranged)");
            return;
        }
        
        if (currentMusicStyle == style) {
            return; // No change needed
        }
        
        writeln("Changing music style from ", currentMusicStyle, " to ", style);
        writeln("Current base music path: '", currentBaseMusicPath, "'");
        writeln("Is music playing: ", isMusicPlaying);
        currentMusicStyle = style;
        
        // If music is currently playing, switch to the new style
        if (isMusicPlaying && currentBaseMusicPath != "") {
            string styleFolderName = (style == 1) ? "original" : "arranged";
            string newMusicPath = "resources/audio/music/" ~ styleFolderName ~ "/" ~ currentBaseMusicPath;
            
            writeln("Switching music to: ", newMusicPath);
            playMusic(newMusicPath, currentMusicVolume, true);
        } else {
            writeln("Not switching music - either not playing or no base path set");
        }
    }
    
    /**
     * Enhanced playMusic that handles music style automatically
     * 
     * Params:
     *   baseFilePath = The filename (e.g., "Main Theme - Bejeweled 2.ogg")
     *   volume = Optional volume override
     *   loop = Whether to loop the music
     */
    bool playMusicWithStyle(string baseFilePath, float volume = -1.0f, bool loop = true) {
        currentBaseMusicPath = baseFilePath;
        string styleFolderName = (currentMusicStyle == 1) ? "original" : "arranged";
        string fullPath = "resources/audio/music/" ~ styleFolderName ~ "/" ~ baseFilePath;
        
        writeln("Playing music with style ", currentMusicStyle, ": ", fullPath);
        return playMusic(fullPath, volume, loop);
    }
    
    /**
     * Start fading out the current music with style-aware next music
     * 
     * Params:
     *   duration = Fade-out duration in seconds
     *   nextMusicBasePath = Base filename for next music (e.g., "Main Theme - Bejeweled 2.ogg")
     *   nextMusicVolume = Volume for the next music (optional)
     *   nextMusicLoop = Whether to loop the next music (optional)
     *   nextMusicDelay = Delay in seconds before starting the next music (optional)
     */
    void fadeOutMusicWithStyle(float duration, string nextMusicBasePath = "", float nextMusicVolume = -1.0f, bool nextMusicLoop = true, float nextMusicDelay = 0.0f) {
        if (nextMusicBasePath != "") {
            // Convert base path to full path with current style
            string styleFolderName = (currentMusicStyle == 1) ? "original" : "arranged";
            string fullPath = "resources/audio/music/" ~ styleFolderName ~ "/" ~ nextMusicBasePath;
            fadeOutMusic(duration, fullPath, nextMusicVolume, nextMusicLoop, nextMusicDelay);
        } else {
            fadeOutMusic(duration, "", nextMusicVolume, nextMusicLoop, nextMusicDelay);
        }
    }
    
    // Sound sequencing system for playing multiple sounds with delays
    private struct QueuedSound {
        string filePath;
        AudioType audioType;
        float volume;
        float delay;
    }
    
    private QueuedSound[] soundQueue;
    private float[] soundQueueTimers;
    
    /**
     * Play multiple sounds in sequence with specified delays
     * 
     * Params:
     *   sounds = Array of sound file paths
     *   delays = Array of delays (in seconds) before each sound plays
     *   audioType = Type of audio for all sounds
     *   volume = Volume override for all sounds
     */
    void playSoundSequence(string[] sounds, float[] delays, AudioType audioType = AudioType.SFX, float volume = -1.0f) {
        if (sounds.length != delays.length) {
            writeln("Error: sounds and delays arrays must be the same length");
            return;
        }
        
        // Clear existing queue
        soundQueue = [];
        soundQueueTimers = [];
        
        // Add sounds to queue
        for (size_t i = 0; i < sounds.length; i++) {
            soundQueue ~= QueuedSound(sounds[i], audioType, volume, delays[i]);
            soundQueueTimers ~= delays[i];
            writeln("AudioManager: Queued sound [", i, "]: ", sounds[i], " with delay: ", delays[i], "s");
        }
        
        writeln("AudioManager: Queued ", sounds.length, " sounds for sequential playback");
    }
    
    /**
     * Update sound queue timers and play queued sounds
     */
    private void updateSoundQueue(float deltaTime) {
        for (size_t i = 0; i < soundQueue.length; i++) {
            soundQueueTimers[i] -= deltaTime;
            
            if (soundQueueTimers[i] <= 0.0f) {
                // Time to play this sound
                QueuedSound sound = soundQueue[i];
                writeln("AudioManager: Playing queued sound: ", sound.filePath);
                bool success = playSound(sound.filePath, sound.audioType, sound.volume);
                
                // Remove this sound from the queue
                soundQueue = soundQueue[0..i] ~ soundQueue[i+1..$];
                soundQueueTimers = soundQueueTimers[0..i] ~ soundQueueTimers[i+1..$];
                i--; // Adjust index since we removed an element
            }
        }
    }
}