package util {
    import flash.geom.Point;

    public class Util {
        public static function secondsSince(d:Date):String {
            return ((new Date().time - d.time) / 1000).toFixed(2) + "s";
        }

        public static function log(v:*):void {
            trace(v);
        }

        public static function closestPoint(point:Point, points:Array):Point {
            if (points.length == 0)
                return null;

            var closest:Point = points[0];

            do {
                var current:Point = points.shift();
                if (Point.distance(point, current) < Point.distance(point, closest))
                    closest = current;
            } while (points.length > 0);

            return closest;
        }

        public static function round(n:Number, places:int = 2):Number {
            return Number(n.toFixed(places));
        }
    }
}