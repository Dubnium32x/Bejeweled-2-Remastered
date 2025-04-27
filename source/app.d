module app;

import raylib;

import std.stdio;
import std.file;
import std.process;
import std.path;

import world.jxl_converter;
import world.screen_manager;
import world.audio_manager;

private ScreenManager screenManager = new ScreenManager();
private AudioManager audioManager = new AudioManager();


void main()
{
	// Initialize Raylib
	InitWindow(800, 600, "Bejeweled 2 Remaster");
	SetTargetFPS(60);

	// Load initial screen (e.g., Title Screen)
	// screenManager.setScreen(new TitleScreen(), ScreenState.TITLE);

	// Main game loop
	while (!WindowShouldClose())
	{
		// Update current screen
		screenManager.update();

		// Begin drawing
		BeginDrawing();
		ClearBackground(RAYWHITE);

		// Draw current screen
		screenManager.draw();

		EndDrawing();
	}

	// Cleanup and close window
	CloseWindow();
}
