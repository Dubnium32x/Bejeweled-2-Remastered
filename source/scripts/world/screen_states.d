module world.screen_states;

// ---- ENUMS ----
enum ScreenState {
    INIT,
    TITLE,
    GAMEPLAY,
    GAMEOVER,
    SETTINGS,
    CREDITS
}

enum GameplayState {
    IN_MENU,
    PLAYING,
    PAUSED,
    GAMEOVER
}

enum TitleState {
    LOGO,
    MAINMENU,
    GAMEMENU,
    OPTIONS,
    NAME_ENTRY
}

enum SettingsState {
    VIDEO,
    AUDIO,
    CONTROLS,
    GAMEPLAY
}

enum GameplayMode {
    CLASSIC,
    ACTION,
    PUZZLE,
    ENDLESS,
    TWILIGHT,
    HYPER,
    COGNITO,
    FINITY,
    ORIGINAL
}

enum Resolution {
    RES_720P,
    RES_1080P,
    RES_1440P,
    RES_4K
}