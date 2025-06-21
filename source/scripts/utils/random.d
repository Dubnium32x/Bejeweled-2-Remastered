module utils.random;

import std.random;

/**
 * Returns a random float value between min and max (inclusive).
 *
 * Params:
 *   min = The minimum value
 *   max = The maximum value
 * Returns: A random float between min and max
 */
float GetRandomFloat(float min, float max) {
    return min + (max - min) * uniform01();
}
