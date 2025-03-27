using System;
using System.Numerics;
using Raylib_cs;

using Bejeweled_2_Remastered.jxl;
using Bejeweled_2_Remastered.Screens;

namespace Bejeweled_2_Remastered
{
    public class Program 
    {
        public static bool isLoading;
        public static float loadingProgress;
        public static bool isLoadingComplete;
        public static bool isLoadingError;
        public static Vector2 screenSize = new Vector2(1280, 720);
        static void Main(string[] args)
        {
            Console.WriteLine("Initializing Raylib window...");

            // Initialize the Raylib window
            Raylib.InitWindow((int)screenSize.X, (int)screenSize.Y, "Bejeweled 2 Remastered");
            Raylib.SetTargetFPS(60);

            while(isLoading)
            {
                // Simulate loading progress
                Console.WriteLine("Loading...");
            }

            Console.WriteLine("Raylib window initialized.");

            ScreenManager screenManager = new ScreenManager();
            SettingsScreen settingsScreen = new SettingsScreen(screenManager);

            Console.WriteLine("Entering main game loop...");

            // Check if the window is ready
            while (!Raylib.IsWindowReady())
            {
                Console.WriteLine("Waiting for window to be ready...");
            }

            // Main game loop
            while (!Raylib.WindowShouldClose())
            {
                if (!Raylib.IsWindowReady())
                {
                    Console.WriteLine("Window is not ready yet.");
                }
                screenManager.Update();
                screenManager.Draw();
            }

            Console.WriteLine("Exiting main game loop...");

            // Close the Raylib window
            Raylib.CloseWindow();
            Console.WriteLine("Raylib window closed.");
        }
    }
}