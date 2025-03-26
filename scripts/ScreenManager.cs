using System;

using Raylib_cs;

using Bejeweled_2_Remastered.jxl;
using Bejeweled_2_Remastered.Screens;

namespace Bejeweled_2_Remastered.Screens
{
    public enum ScreenState
    {
        Title,
        MainMenu,
        Classic,
        Zen,
        Action,
        Puzzle,
        Settings,
        Credits,
        Exit
    }

    public interface IScreen
    {
        void Load();
        void Unload();
        void Update();
        void Draw();
    }

    public class ScreenManager
    {
        private ScreenState currentState;
        private IScreen currentScreen;

        public ScreenManager()
        {
            ChangeState(ScreenState.MainMenu);
        }

        public void ChangeState(ScreenState newState)
        {
            if (currentScreen != null)
            {
                currentScreen.Unload();
            }

            currentState = newState;

            switch (currentState)
            {
                case ScreenState.Title:
                    currentScreen = new TitleScreen();
                    break;
                case ScreenState.MainMenu:
                    currentScreen = new MainMenuScreen();
                    break;
                case ScreenState.Classic:
                    currentScreen = new GameplayScreen();
                    break;
                case ScreenState.Zen:
                    currentScreen = new GameplayScreen();
                    break;
                case ScreenState.Action:
                    currentScreen = new GameplayScreen();
                    break;
                case ScreenState.Puzzle:
                    currentScreen = new GameplayScreen();
                    break;
                case ScreenState.Settings:
                    currentScreen = new SettingsScreen();
                    break;
                case ScreenState.Credits:
                    currentScreen = new CreditsScreen();
                    break;
                case ScreenState.Exit:
                    Raylib.CloseWindow();
                    break;
            }

            if (currentScreen != null)
            {
                currentScreen.Load();
            }
        }

        public void Update()
        {
            if (currentScreen != null)
            {
                currentScreen.Update();
            }
        }

        public void Draw()
        {
            if (currentScreen != null)
            {
                currentScreen.Draw();
            }
        }
    }
}