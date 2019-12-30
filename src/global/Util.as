package global {
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

        public static function toArray(iterable:*):Array {
            var arr:Array = [];
            for each (var o:Object in iterable)
                arr.push(o);
            return arr;
        }

        public static function colorBetweenColors(color1:uint = 0xFFFFFF, color2:uint = 0x000000, percent:Number = 0.5):uint {
            if (percent < 0)
                percent = 0;
            if (percent > 1)
                percent = 1;

            var r:uint = color1 >> 16;
            var g:uint = color1 >> 8 & 0xFF;
            var b:uint = color1 & 0xFF;

            r += ((color2 >> 16) - r) * percent;
            g += ((color2 >> 8 & 0xFF) - g) * percent;
            b += ((color2 & 0xFF) - b) * percent;

            return (r << 16 | g << 8 | b);
        }

        public static function degreesBetweenTwoPoints(p1:Point, p2:Point):Number {
            return radiansToDegrees(Math.atan2(p2.y - p1.y, p2.x - p1.x));
        }


        public static function differenceBetweenTwoDegrees(d1:Number, d2:Number):Number {
            return Math.abs((d1 + 180 - d2) % 360 - 180);
        }

        public static function radiansToDegrees(value:Number):Number {
            return value * 180 / Math.PI;
        }

        public static function degreesToRadians(value:Number):Number {
            return value * Math.PI / 180
        }

        public static function pointFromAngleAndDistance(point:Point, angle:Number, distance:Number):Point {
            return new Point(point.x + Math.cos(angle) * distance, point.y + Math.sin(angle) * distance);
        }
    }
}