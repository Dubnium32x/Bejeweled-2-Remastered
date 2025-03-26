using System;
using System.Collections.Generic;
using System.IO;

using Raylib_cs;
using Bejeweled_2_Remastered.jxl;
using Bejeweled_2_Remastered.Screens;

namespace Bejeweled_2_Remastered
{
    public class Program 
    {
        static void Main(string[] args)
        {
            // Initialize the Raylib window
            Raylib.InitWindow(800, 600, "Bejeweled 2 Clone");
            Raylib.SetTargetFPS(60);

            ScreenManager screenManager = new ScreenManager();

            // Main game loop
            while (!Raylib.WindowShouldClose())
            {
                screenManager.Update();
                screenManager.Draw();
            }

            // Close the Raylib window
            Raylib.CloseWindow();
        }
    }
}