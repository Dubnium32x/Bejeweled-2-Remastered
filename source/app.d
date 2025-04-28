module app;

import raylib;
import std.stdio;
import std.file;
import std.process;
import std.path;
import std.string;
import std.algorithm;

import world.jxl_converter;
import world.game_manager;

// data pool
public Texture[] textures;

// Define RAYWHITE if not already defined
enum RAYWHITE = Color(245, 245, 245, 255);

private GameManager gameManager;
// private string jxlImagePath = "resources/bgem2_ver2.jxl"; // Update with your JXL image path
// private Texture testTexture;

void main() {
    writeln("Starting main()");
    // Use singleton pattern for GameManager
    gameManager = GameManager.getInstance();
    writeln("GameManager initialized");
    auto displayManager = gameManager.displayManager;
    assert(displayManager !is null, "displayManager is null!");
    writeln("DisplayManager initialized");

    // Initialize the Raylib window FIRST
    InitWindow(800, 450, "Bejeweled 2 Remaster");
    SetTargetFPS(60);

	// Texture testTexture;
	// writeln("Raylib window initialized");

	// // Convert JXL image to PNG if needed
	// jxlToPng(jxlImagePath, "resources/bgem2_ver2.png");
	// // Load the converted PNG texture
	// testTexture = LoadTexture("resources/bgem2_ver2.png");
	// // send texture to data pool
	// textures ~= testTexture;

    writeln("Display settings applied");

    while(!WindowShouldClose()) {
        // Update game state
        gameManager.update();

        // Begin drawing
        BeginDrawing();
        ClearBackground(RAYWHITE);

		// draw the texture to verify it loads correctly
		// DrawTexture(testTexture, 0, 0, Colors.RAYWHITE);

        // Render game state
        gameManager.render();

        EndDrawing();
    }

	// Cleanup resources
	foreach (file; dirEntries("", SpanMode.shallow)) {
		if (file.name.endsWith(".png")) {
			try {
				remove(file.name);
			} catch (Exception e) {
				writeln("Failed to remove ", file.name, ": ", e.msg);
			}
		}
	}
	// Close the Raylib window
	CloseWindow();
}