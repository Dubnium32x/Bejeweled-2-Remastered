module world.screen_states;

enum ScreenState {
    INIT,
    TITLE,
    GAMEPLAY,
    GAMEOVER
}

enum GameplayState {
    PLAYING,
    PAUSED,
    GAMEOVER
}

enum TitleState {
    LOGO,
    MAINMENU
}

enum GameplayType {
    CLASSIC,
    PUZZLE,
    ACTION,
    ENDLESS,
    IN-COGNITO // Custom gameplay mode
}