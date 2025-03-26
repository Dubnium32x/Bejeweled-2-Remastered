using System;
using Raylib_cs;

namespace Bejeweled_2_Remastered
{
    public class Program 
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Initializing Raylib window...");

            // Initialize the Raylib window
            Raylib.InitWindow(800, 600, "Bejeweled 2 Clone");
            Raylib.SetTargetFPS(60);

            Console.WriteLine("Raylib window initialized.");

            ScreenManager screenManager = new ScreenManager();

            Console.WriteLine("Entering main game loop...");

            // Main game loop
            while (!Raylib.WindowShouldClose())
            {
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