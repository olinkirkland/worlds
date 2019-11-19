package {
    public class Color {
        public static const white:uint = 0xffffff;
        public static const grey:uint = 0xcccccc;
        public static const black:uint = 0x000000;

        public static const red:uint = 0xeb4034;
        public static const green:uint = 0x35db3d;
        public static const yellow:uint = 0xedd04e;
        public static const blue:uint = 0x34baeb;


        private static var all:Array = [red, green, yellow, blue];

        public static function get random():uint {
            return all[int(Math.random() * all.length)];
        }
    }
}
