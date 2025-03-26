using System;
using System.Diagnostics;
using System.IO;

namespace Bejeweled_2_Remastered.jxl
{
    public static class JxlConverter
    {
        public static string ConvertJxlToPng(string jxlFilePath)
        {
            string pngFilePath = jxlFilePath.Replace(".jxl", ".png");

            // Debug: Print the paths for conversion
            Console.WriteLine($"Converting {jxlFilePath} to {pngFilePath}");

            try
            {
                // Use ffmpeg to convert JXL to PNG
                ProcessStartInfo startInfo = new ProcessStartInfo
                {
                    FileName = "ffmpeg",
                    Arguments = $"-y -i \"{jxlFilePath}\" -frames:v 1 -update 1 \"{pngFilePath}\"",
                    RedirectStandardOutput = true,
                    RedirectStandardError = true,
                    UseShellExecute = false,
                    CreateNoWindow = true
                };

                using (Process process = new Process { StartInfo = startInfo })
                {
                    process.Start();

                    // Capture and log all output
                    string output = process.StandardOutput.ReadToEnd();
                    string error = process.StandardError.ReadToEnd();
                    process.WaitForExit();

                    Console.WriteLine("FFmpeg Output:");
                    Console.WriteLine(output);
                    Console.WriteLine("FFmpeg Error:");
                    Console.WriteLine(error);

                    if (process.ExitCode != 0)
                    {
                        throw new Exception($"Conversion failed with exit code {process.ExitCode}");
                    }

                    Console.WriteLine("Conversion completed successfully.");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error during conversion: {ex.Message}");
                throw;
            }

            return pngFilePath;
        }
    }
}