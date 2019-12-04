package {
    public class Util {
        public static function secondsSince(d:Date):String {
            return ((new Date().time - d.time) / 1000).toFixed(2) + "s";
        }
    }
}