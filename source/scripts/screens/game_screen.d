module screens.game_screen;

import raylib;

import std.stdio;
import std.array;
import std.algorithm;
import std.conv : to;
import std.file;
import std.math;

import data;
import world.screen_manager;
import world.screen_states;
import world.memory_manager;
import world.audio_manager;

/*

    NOTES

    The game board slides in from the right side.

*/

// ---- LOCAL VARIABLES ----


