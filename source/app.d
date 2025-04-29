module app;

import raylib;
import std.stdio;
import std.file;
import std.process;
import std.path;
import std.string;
import std.algorithm;
import std.random : uniform, Random, unpredictableSeed;
import std.conv : to;

import world.jxl_converter;
import world.game_manager;
import image_paths;

private GameManager gameManager = new GameManager();

void main() {
    InitWindow(800, 600, "Bejeweled 2 Remastered");
    SetTargetFPS(60);

    gameManager.initialize();
    while (!WindowShouldClose()) {
        gameManager.update();
        gameManager.render();
    }
    CloseWindow();
}