module world.memory_manager;

import raylib;
import std.stdio;
import std.string;
import std.path;
import std.file;
import std.algorithm;
import std.array;
import std.typecons : Tuple;
import std.conv : to;

/**
 * Memory Manager
 * 
 * Manages and caches game resources to optimize memory usage and loading times.
 * Tracks textures, sounds, music, fonts, and shaders.
 */
class MemoryManager {
    private {
        // Cached resources
        Texture2D[string] textureCache;
        Sound[string] soundCache;
        Music[string] musicCache;
        Font[string] fontCache;
        Shader[string] shaderCache;
        
        // Alpha map associations
        string[string] textureAlphaMaps; // Maps base texture path to alpha map path

        // Resource usage statistics
        size_t totalTextureMemory = 0;
        size_t totalSoundMemory = 0;
        size_t totalMusicMemory = 0;
        size_t totalFontMemory = 0;
        size_t totalShaderMemory = 0;

        // Singleton instance
        __gshared MemoryManager _instance;
    }

    /**
     * Get singleton instance
     */
    static MemoryManager instance() {
        if (_instance is null) {
            synchronized {
                if (_instance is null) {
                    _instance = new MemoryManager();
                }
            }
        }
        return _instance;
    }

    /**
     * Initialize the memory manager
     */
    void initialize() {
        writeln("MemoryManager initialized");
    }

    /**
     * Load and cache a texture
     * 
     * Params:
     *   filePath = Path to the texture file
     *   forceReload = Whether to reload the texture even if it's cached
     * 
     * Returns: The loaded texture
     */
    Texture2D loadTexture(string filePath, bool forceReload = false) {
        if (!forceReload && filePath in textureCache) {
            return textureCache[filePath];
        }

        // If we're reloading, unload the previous texture first
        if (forceReload && filePath in textureCache) {
            UnloadTexture(textureCache[filePath]);
            totalTextureMemory -= estimateTextureMemory(textureCache[filePath]);
            textureCache.remove(filePath);
        }

        Texture2D texture = LoadTexture(filePath.toStringz);
        if (texture.id == 0) {
            writeln("ERROR: Failed to load texture: ", filePath);
            // Return an empty texture
            return texture;
        }
        
        textureCache[filePath] = texture;
        
        // Update memory usage statistics
        totalTextureMemory += estimateTextureMemory(texture);
        
        return texture;
    }

    /**
     * Load and cache a sound
     * 
     * Params:
     *   filePath = Path to the sound file
     *   forceReload = Whether to reload the sound even if it's cached
     * 
     * Returns: The loaded sound
     */
    Sound loadSound(string filePath, bool forceReload = false) {
        if (!forceReload && filePath in soundCache) {
            return soundCache[filePath];
        }

        // If we're reloading, unload the previous sound first
        if (forceReload && filePath in soundCache) {
            UnloadSound(soundCache[filePath]);
            totalSoundMemory -= estimateSoundMemory(soundCache[filePath]);
            soundCache.remove(filePath);
        }

        Sound sound = LoadSound(filePath.toStringz);
        if (sound.frameCount <= 0) {
            writeln("ERROR: Failed to load sound: ", filePath);
            // Return the invalid sound
            return sound;
        }
        
        soundCache[filePath] = sound;
        
        // Update memory usage statistics
        totalSoundMemory += estimateSoundMemory(sound);
        
        return sound;
    }

    /**
     * Load and cache music
     * 
     * Params:
     *   filePath = Path to the music file
     *   forceReload = Whether to reload the music even if it's cached
     * 
     * Returns: The loaded music
     */
    Music loadMusic(string filePath, bool forceReload = false) {
        if (!forceReload && filePath in musicCache) {
            return musicCache[filePath];
        }

        // If we're reloading, unload the previous music first
        if (forceReload && filePath in musicCache) {
            UnloadMusicStream(musicCache[filePath]);
            totalMusicMemory -= estimateMusicMemory(musicCache[filePath]);
            musicCache.remove(filePath);
        }

        Music music = LoadMusicStream(filePath.toStringz);
        if (music.ctxData == null) {
            writeln("ERROR: Failed to load music: ", filePath);
            // Return the invalid music
            return music;
        }
        
        musicCache[filePath] = music;
        
        // Update memory usage statistics
        totalMusicMemory += estimateMusicMemory(music);
        
        return music;
    }

    /**
     * Load and cache a font
     * 
     * Params:
     *   filePath = Path to the font file
     *   fontSize = Size of the font to load
     *   forceReload = Whether to reload the font even if it's cached
     * 
     * Returns: The loaded font
     */
    Font loadFont(string filePath, int fontSize = 10, bool forceReload = false) {
        string cacheKey = filePath ~ "_" ~ fontSize.to!string;
        
        if (!forceReload && cacheKey in fontCache) {
            return fontCache[cacheKey];
        }

        // If we're reloading, unload the previous font first
        if (forceReload && cacheKey in fontCache) {
            UnloadFont(fontCache[cacheKey]);
            totalFontMemory -= estimateFontMemory(fontCache[cacheKey]);
            fontCache.remove(cacheKey);
        }

        Font font = LoadFontEx(filePath.toStringz, fontSize, null, 0);
        fontCache[cacheKey] = font;
        
        // Update memory usage statistics
        totalFontMemory += estimateFontMemory(font);
        
        return font;
    }

    /**
     * Load and cache a shader
     * 
     * Params:
     *   vsFilePath = Path to the vertex shader file (can be null)
     *   fsFilePath = Path to the fragment shader file (can be null)
     *   forceReload = Whether to reload the shader even if it's cached
     * 
     * Returns: The loaded shader
     */
    Shader loadShader(string vsFilePath, string fsFilePath, bool forceReload = false) {
        string cacheKey = vsFilePath ~ "|" ~ fsFilePath;
        
        if (!forceReload && cacheKey in shaderCache) {
            return shaderCache[cacheKey];
        }

        // If we're reloading, unload the previous shader first
        if (forceReload && cacheKey in shaderCache) {
            UnloadShader(shaderCache[cacheKey]);
            totalShaderMemory -= estimateShaderMemory(shaderCache[cacheKey]);
            shaderCache.remove(cacheKey);
        }

        Shader shader = LoadShader(
            vsFilePath.length > 0 ? vsFilePath.toStringz : null,
            fsFilePath.length > 0 ? fsFilePath.toStringz : null
        );
        
        shaderCache[cacheKey] = shader;
        
        // Update memory usage statistics
        totalShaderMemory += estimateShaderMemory(shader);
        
        return shader;
    }

    /**
     * Unload a specific texture from the cache
     * 
     * Params:
     *   filePath = Path to the texture file
     */
    void unloadTexture(string filePath) {
        if (filePath in textureCache) {
            UnloadTexture(textureCache[filePath]);
            totalTextureMemory -= estimateTextureMemory(textureCache[filePath]);
            textureCache.remove(filePath);
        }
    }

    /**
     * Unload a specific sound from the cache
     * 
     * Params:
     *   filePath = Path to the sound file
     */
    void unloadSound(string filePath) {
        if (filePath in soundCache) {
            UnloadSound(soundCache[filePath]);
            totalSoundMemory -= estimateSoundMemory(soundCache[filePath]);
            soundCache.remove(filePath);
        }
    }

    /**
     * Unload a specific music from the cache
     * 
     * Params:
     *   filePath = Path to the music file
     */
    void unloadMusic(string filePath) {
        if (filePath in musicCache) {
            UnloadMusicStream(musicCache[filePath]);
            totalMusicMemory -= estimateMusicMemory(musicCache[filePath]);
            musicCache.remove(filePath);
        }
    }

    /**
     * Unload a specific font from the cache
     * 
     * Params:
     *   filePath = Path to the font file
     *   fontSize = Size of the font
     */
    void unloadFont(string filePath, int fontSize = 10) {
        string cacheKey = filePath ~ "_" ~ fontSize.to!string;
        if (cacheKey in fontCache) {
            UnloadFont(fontCache[cacheKey]);
            totalFontMemory -= estimateFontMemory(fontCache[cacheKey]);
            fontCache.remove(cacheKey);
        }
    }

    /**
     * Unload a specific shader from the cache
     * 
     * Params:
     *   vsFilePath = Path to the vertex shader file
     *   fsFilePath = Path to the fragment shader file
     */
    void unloadShader(string vsFilePath, string fsFilePath) {
        string cacheKey = vsFilePath ~ "|" ~ fsFilePath;
        if (cacheKey in shaderCache) {
            UnloadShader(shaderCache[cacheKey]);
            totalShaderMemory -= estimateShaderMemory(shaderCache[cacheKey]);
            shaderCache.remove(cacheKey);
        }
    }

    /**
     * Get a texture from the cache
     * 
     * Params:
     *   filePath = Path to the texture file
     * 
     * Returns: The cached texture or a default texture if not found
     */
    Texture2D getTexture(string filePath) {
        if (filePath in textureCache) {
            return textureCache[filePath];
        }
        
        return loadTexture(filePath);
    }

    /**
     * Get a sound from the cache
     * 
     * Params:
     *   filePath = Path to the sound file
     * 
     * Returns: The cached sound or null if not found
     */
    Sound getSound(string filePath) {
        if (filePath in soundCache) {
            return soundCache[filePath];
        }
        
        return loadSound(filePath);
    }

    /**
     * Get music from the cache
     * 
     * Params:
     *   filePath = Path to the music file
     * 
     * Returns: The cached music or null if not found
     */
    Music getMusic(string filePath) {
        if (filePath in musicCache) {
            return musicCache[filePath];
        }
        
        return loadMusic(filePath);
    }

    /**
     * Get a font from the cache
     * 
     * Params:
     *   filePath = Path to the font file
     *   fontSize = Size of the font
     * 
     * Returns: The cached font or null if not found
     */
    Font getFont(string filePath, int fontSize = 10) {
        string cacheKey = filePath ~ "_" ~ fontSize.to!string;
        if (cacheKey in fontCache) {
            return fontCache[cacheKey];
        }
        
        return loadFont(filePath, fontSize);
    }

    /**
     * Get a shader from the cache
     * 
     * Params:
     *   vsFilePath = Path to the vertex shader file
     *   fsFilePath = Path to the fragment shader file
     * 
     * Returns: The cached shader or null if not found
     */
    Shader getShader(string vsFilePath, string fsFilePath) {
        string cacheKey = vsFilePath ~ "|" ~ fsFilePath;
        if (cacheKey in shaderCache) {
            return shaderCache[cacheKey];
        }
        
        return loadShader(vsFilePath, fsFilePath);
    }

    /**
     * Check if a texture is in the cache
     * 
     * Params:
     *   filePath = Path to the texture file
     * 
     * Returns: true if the texture is cached, false otherwise
     */
    bool hasTexture(string filePath) {
        return (filePath in textureCache) !is null;
    }

    /**
     * Check if a sound is in the cache
     * 
     * Params:
     *   filePath = Path to the sound file
     * 
     * Returns: true if the sound is cached, false otherwise
     */
    bool hasSound(string filePath) {
        return (filePath in soundCache) !is null;
    }

    /**
     * Check if music is in the cache
     * 
     * Params:
     *   filePath = Path to the music file
     * 
     * Returns: true if the music is cached, false otherwise
     */
    bool hasMusic(string filePath) {
        return (filePath in musicCache) !is null;
    }

    /**
     * Check if a font is in the cache
     * 
     * Params:
     *   filePath = Path to the font file
     *   fontSize = Size of the font
     * 
     * Returns: true if the font is cached, false otherwise
     */
    bool hasFont(string filePath, int fontSize = 10) {
        string cacheKey = filePath ~ "_" ~ fontSize.to!string;
        return (cacheKey in fontCache) !is null;
    }

    /**
     * Check if a shader is in the cache
     * 
     * Params:
     *   vsFilePath = Path to the vertex shader file
     *   fsFilePath = Path to the fragment shader file
     * 
     * Returns: true if the shader is cached, false otherwise
     */
    bool hasShader(string vsFilePath, string fsFilePath) {
        string cacheKey = vsFilePath ~ "|" ~ fsFilePath;
        return (cacheKey in shaderCache) !is null;
    }

    /**
     * Unload all cached resources
     */
    void unloadAllResources() {
        // Unload all textures
        foreach (key, texture; textureCache) {
            UnloadTexture(texture);
        }
        textureCache = null;
        totalTextureMemory = 0;

        // Unload all sounds
        foreach (key, sound; soundCache) {
            UnloadSound(sound);
        }
        soundCache = null;
        totalSoundMemory = 0;

        // Unload all music
        foreach (key, music; musicCache) {
            UnloadMusicStream(music);
        }
        musicCache = null;
        totalMusicMemory = 0;

        // Unload all fonts
        foreach (key, font; fontCache) {
            UnloadFont(font);
        }
        fontCache = null;
        totalFontMemory = 0;

        // Unload all shaders
        foreach (key, shader; shaderCache) {
            UnloadShader(shader);
        }
        shaderCache = null;
        totalShaderMemory = 0;

        writeln("All cached resources unloaded");
    }

    /**
     * Preload common resources to speed up loading times
     * 
     * Params:
     *   texturePaths = Array of texture paths to preload
     *   soundPaths = Array of sound paths to preload
     *   musicPaths = Array of music paths to preload
     *   fontPaths = Array of font paths to preload with optional sizes
     * 
     * Returns: true if all resources were loaded successfully, false otherwise
     */
    bool preloadResources(
        string[] texturePaths = [], 
        string[] soundPaths = [], 
        string[] musicPaths = [], 
        Tuple!(string, int)[] fontPaths = []
    ) {
        bool allResourcesLoaded = true;
        
        // Preload textures with alpha maps
        if (texturePaths.length > 0) {
            bool texturesLoaded = preloadTexturesWithAlphaMaps(texturePaths);
            if (!texturesLoaded) {
                allResourcesLoaded = false;
            }
        }

        // Preload sounds
        foreach (soundPath; soundPaths) {
            if (exists(soundPath)) {
                Sound sound = loadSound(soundPath);
                if (sound.frameCount <= 0) {
                    writeln("ERROR: Failed to load sound during preload: ", soundPath);
                    allResourcesLoaded = false;
                }
            } else {
                writeln("Warning: Sound file not found: ", soundPath);
                allResourcesLoaded = false;
            }
        }

        // Preload music
        foreach (musicPath; musicPaths) {
            if (exists(musicPath)) {
                Music music = loadMusic(musicPath);
                if (music.ctxData == null) {
                    writeln("ERROR: Failed to load music during preload: ", musicPath);
                    allResourcesLoaded = false;
                }
            } else {
                writeln("Warning: Music file not found: ", musicPath);
                allResourcesLoaded = false;
            }
        }

        // Preload fonts
        foreach (fontInfo; fontPaths) {
            if (exists(fontInfo[0])) {
                Font font = loadFont(fontInfo[0], fontInfo[1]);
                if (font.texture.id == 0) {
                    writeln("ERROR: Failed to load font during preload: ", fontInfo[0]);
                    allResourcesLoaded = false;
                }
            } else {
                writeln("Warning: Font file not found: ", fontInfo[0]);
                allResourcesLoaded = false;
            }
        }

        writefln("Preloaded resources: %d textures, %d sounds, %d music tracks, %d fonts", 
            texturePaths.length, soundPaths.length, musicPaths.length, fontPaths.length);
            
        return allResourcesLoaded;
    }

    /**
     * Get memory usage statistics
     * 
     * Returns: String with memory usage information
     */
    string getMemoryUsageStats() {
        return format(
            "Memory Usage:\n" ~
            "  Textures: %.2f MB (%d cached)\n" ~
            "  Sounds: %.2f MB (%d cached)\n" ~
            "  Music: %.2f MB (%d cached)\n" ~
            "  Fonts: %.2f MB (%d cached)\n" ~
            "  Shaders: %.2f MB (%d cached)\n" ~
            "  Total: %.2f MB",
            totalTextureMemory / 1024.0 / 1024.0, textureCache.length,
            totalSoundMemory / 1024.0 / 1024.0, soundCache.length,
            totalMusicMemory / 1024.0 / 1024.0, musicCache.length,
            totalFontMemory / 1024.0 / 1024.0, fontCache.length,
            totalShaderMemory / 1024.0 / 1024.0, shaderCache.length,
            (totalTextureMemory + totalSoundMemory + totalMusicMemory + totalFontMemory + totalShaderMemory) / 1024.0 / 1024.0
        );
    }

    /**
     * Estimate memory usage of a texture
     */
    private size_t estimateTextureMemory(Texture2D texture) {
        // Calculate memory usage based on dimensions and format
        int bytesPerPixel = 4; // Assume RGBA format (4 bytes per pixel)
        return texture.width * texture.height * bytesPerPixel;
    }

    /**
     * Estimate memory usage of a sound
     */
    private size_t estimateSoundMemory(Sound sound) {
        // This is a rough estimate since Raylib doesn't expose exact memory usage
        // Assume 16-bit stereo sound at 44.1 kHz
        // Approximation based on typical sound resource sizes
        return 512 * 1024; // Default to 512KB per sound
    }

    /**
     * Estimate memory usage of music
     */
    private size_t estimateMusicMemory(Music music) {
        // This is a rough estimate since Raylib doesn't expose exact memory usage
        // Using a default value for music streams
        return 2 * 1024 * 1024; // Default to 2MB per music track
    }

    /**
     * Estimate memory usage of a font
     */
    private size_t estimateFontMemory(Font font) {
        // Calculate memory usage based on font glyphs
        size_t memory = 0;
        
        // Base font structure
        memory += 256; // Base font structure size
        
        // Texture memory
        memory += estimateTextureMemory(font.texture);
        
        // Glyph data
        memory += font.glyphCount * (8 + 16); // Rectangle + additional data per glyph
        
        return memory;
    }

    /**
     * Estimate memory usage of a shader
     */
    private size_t estimateShaderMemory(Shader shader) {
        // This is a rough estimate since Raylib doesn't expose exact memory usage
        // Using a default value for shaders
        return 128 * 1024; // Default to 128KB per shader
    }

    /**
     * Clean up resources that haven't been used for a while
     */
    void cleanupUnusedResources() {
        // Future implementation - track resource usage timestamps
        // and unload resources that haven't been used for a set period
    }

    /**
     * Perform garbage collection and release unused memory
     */
    void performGC() {
        import core.memory : GC;
        GC.collect();
    }

    /**
     * Save the current cache state for quicker loading next time
     * 
     * Params:
     *   filePath = Path to save the cache state
     */
    void saveCacheState(string filePath) {
        // Future implementation - save cache state to disk
    }

    /**
     * Load cache state from a file
     * 
     * Params:
     *   filePath = Path to the cache state file
     */
    void loadCacheState(string filePath) {
        // Future implementation - load cache state from disk
    }

    /**
     * Associate an alpha map with a base texture
     * 
     * Params:
     *   baseTexturePath = Path to the base texture
     *   alphaMapPath = Path to the alpha map texture
     */
    void associateAlphaMap(string baseTexturePath, string alphaMapPath) {
        if (!hasTexture(baseTexturePath)) {
            loadTexture(baseTexturePath);
        }
        
        if (!hasTexture(alphaMapPath)) {
            loadTexture(alphaMapPath);
        }
        
        textureAlphaMaps[baseTexturePath] = alphaMapPath;
        writefln("Associated alpha map %s with texture %s", alphaMapPath, baseTexturePath);
    }
    
    /**
     * Get the alpha map path associated with a texture
     * 
     * Params:
     *   baseTexturePath = Path to the base texture
     * 
     * Returns: Path to the associated alpha map, or null if none
     */
    string getAlphaMapPath(string baseTexturePath) {
        if (baseTexturePath in textureAlphaMaps) {
            return textureAlphaMaps[baseTexturePath];
        }
        return null;
    }
    
    /**
     * Check if a texture has an associated alpha map
     * 
     * Params:
     *   baseTexturePath = Path to the base texture
     * 
     * Returns: true if the texture has an alpha map, false otherwise
     */
    bool hasAlphaMap(string baseTexturePath) {
        return (baseTexturePath in textureAlphaMaps) !is null;
    }
    
    /**
     * Get the alpha map texture associated with a texture
     * 
     * Params:
     *   baseTexturePath = Path to the base texture
     * 
     * Returns: The alpha map texture, or a default texture if none
     */
    Texture2D getAlphaMap(string baseTexturePath) {
        if (baseTexturePath in textureAlphaMaps) {
            string alphaMapPath = textureAlphaMaps[baseTexturePath];
            if (alphaMapPath in textureCache) {
                return textureCache[alphaMapPath];
            }
        }
        
        // Return an empty texture if no alpha map is found
        Texture2D emptyTexture;
        return emptyTexture;
    }

    /**
     * Preload textures and automatically associate alpha maps
     * 
     * Params:
     *   texturePaths = Array of texture paths to preload
     * 
     * Returns: true if all textures were loaded successfully, false otherwise
     */
    bool preloadTexturesWithAlphaMaps(string[] texturePaths) {
        bool allLoaded = true;
        
        // First, load all textures
        foreach (texturePath; texturePaths) {
            if (exists(texturePath)) {
                Texture2D texture = loadTexture(texturePath);
                if (texture.id == 0) {
                    writeln("ERROR: Failed to load texture during preload: ", texturePath);
                    allLoaded = false;
                }
            } else {
                writeln("Warning: Texture not found: ", texturePath);
                allLoaded = false;
            }
        }
        
        // Then look for alpha maps (textures ending with "_")
        foreach (texturePath; texturePaths) {
            if (texturePath.endsWith("_.png")) {
                // This is an alpha map, find the base texture
                string baseTexturePath = texturePath[0..$-5] ~ ".png";
                
                if (hasTexture(baseTexturePath)) {
                    // Associate the alpha map with the base texture
                    associateAlphaMap(baseTexturePath, texturePath);
                }
            }
        }
        
        return allLoaded;
    }
}