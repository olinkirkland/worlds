package global {
    public class Color {
        // Shades
        public static const white:uint = 0xffffff;
        public static const grey:uint = 0xcccccc;
        public static const black:uint = 0x000000;

        // Game Colors
        public static const red:uint = 0xeb4034;
        public static const orange:uint = 0xffa550;
        public static const yellow:uint = 0xedd04e;
        public static const green:uint = 0x35db3d;
        public static const blue:uint = 0x1e90ff;
        public static const darkBlue:uint = 0x00008b;

        // UI
        public static const primary:uint = 0x2185D0;
        public static const secondary:uint = 0xE0E1E2;
        public static const background:uint = 0xF8F8F9;

        public static const darkBody:uint = 0x5A5A5A;
        public static const lightBody:uint = 0xFFFFFF;

        private static var all:Array = [red, orange, green, yellow, green, blue];

        public static function get random():uint {
            return all[int(Math.random() * all.length)];
        }
    }
}
