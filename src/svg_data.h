#ifndef SVG_DATA_H
#define SVG_DATA_H

// SVG data for display - landscape scene
// This SVG is 240x240 pixels to match the round display
const char * svg_data = 
    "<svg width=\"240\" height=\"240\" viewBox=\"0 0 240 240\" xmlns=\"http://www.w3.org/2000/svg\">"
    // Circle background representing the sky (fills the whole display)
    "<circle cx=\"120\" cy=\"120\" r=\"120\" fill=\"#87CEEB\"/>"
    // Sun
    "<circle cx=\"190\" cy=\"60\" r=\"30\" fill=\"#FFD700\"/>"
    // Mountains
    "<path d=\"M0 160 L80 90 L160 160\" fill=\"#6B8E23\"/>"
    "<path d=\"M80 160 L170 70 L240 160\" fill=\"#556B2F\"/>"
    // Grass field
    "<path d=\"M0 160 Q120 150 240 160 L240 240 L0 240 Z\" fill=\"#228B22\"/>"
    // Tree trunk
    "<rect x=\"50\" y=\"130\" width=\"10\" height=\"30\" fill=\"#8B4513\"/>"
    // Tree foliage
    "<path d=\"M35 130 L75 130 L55 90 Z\" fill=\"#228B22\"/>"
    "<path d=\"M40 100 L70 100 L55 60 Z\" fill=\"#228B22\"/>"
    "</svg>";

#endif // SVG_DATA_H