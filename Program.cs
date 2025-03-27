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
        public static Vector2 screenSize = new Vector2(1280, 720);
        static void Main(string[] args)
        {
            Console.WriteLine("Initializing Raylib window...");

            // Initialize the Raylib window
            Raylib.InitWindow((int)screenSize.X, (int)screenSize.Y, "Bejeweled 2 Remastered");
            Raylib.SetTargetFPS(60);

            Console.WriteLine("Raylib window initialized.");

            ScreenManager screenManager = new ScreenManager();
            SettingsScreen settingsScreen = new SettingsScreen(screenManager);

            Console.WriteLine("Entering main game loop...");

            // Main game loop
            while (!Raylib.WindowShouldClose())
            {
                isLoading = false;
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