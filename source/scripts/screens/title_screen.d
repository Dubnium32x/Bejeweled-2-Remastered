module screens.title_screen;

import raylib;

import std.stdio;
import std.file;
import std.json;
import std.path;
import std.process;
import std.string;
import std.algorithm : map;
import std.array;

import world.game_manager;
import world.jxl_converter;

// ---- ENUMS ----
enum TitleScreenState {
    LOGO,
    MAINMENU,
    OPTIONS,
    EXIT
}
