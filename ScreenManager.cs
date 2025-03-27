using System;
using System.Numerics;
using Raylib_cs;

using Bejeweled_2_Remastered.Screens;

namespace Bejeweled_2_Remastered
{
    public class ScreenManager
    {
        private ScreenState currentState;
        private IScreen currentScreen = null; // Initialize to null

        public ScreenManager()
        {
            Console.WriteLine("Initializing ScreenManager...");
            ChangeState(ScreenState.TitleScreen);
            Console.WriteLine("ScreenManager initialized.");
        }

        public void ChangeState(ScreenState newState)
        {
            Console.WriteLine($"Changing state to {newState}...");

            if (currentScreen != null)
            {
                Console.WriteLine("Unloading current screen...");
                currentScreen.Unload();
                Console.WriteLine("Current screen unloaded.");
            }

            currentState = newState;

            switch (currentState)
            {
                case ScreenState.MainMenu:
                    currentScreen = new MainMenuScreen(this);
                    break;
                case ScreenState.Gameplay:
                    currentScreen = new GameplayScreen(this);
                    break;
                case ScreenState.Settings:
                    currentScreen = new SettingsScreen(this);
                    break;
                case ScreenState.Exit:
                    Raylib.CloseWindow();
                    break;
                case ScreenState.TitleScreen:
                    currentScreen = new TitleScreen(this);
                    break;
            }

            if (currentScreen != null)
            {
                Console.WriteLine("Loading new screen...");
                currentScreen.Load();
                Console.WriteLine("New screen loaded.");
            }
        }

        public void Update()
        {
            if (currentScreen != null)
            {
                currentScreen.Update();
            }

            // Handle screen resolution

        }

        public void Draw()
        {
            if (currentScreen != null && Program.isLoading == false)
            {
                currentScreen.Draw();
            }
        }
    }
}