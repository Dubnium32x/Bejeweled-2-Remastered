module world.jxl_converter;

import std.stdio;
import std.file;
import std.process;
import std.path;

string jxlToPng(string jxlPath, string pngPath = "")
{
    // Use djxl (from libjxl tools) to convert JXL to PNG
    // Ensure djxl is installed and in PATH
    if (pngPath.length == 0)
        pngPath = jxlPath.baseName ~ ".png";

    auto result = execute(["djxl", jxlPath, pngPath]);
    if (result.status != 0)
        throw new Exception("djxl failed: " ~ result.output);

    return pngPath;
}