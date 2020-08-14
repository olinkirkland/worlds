package global
{
    import flash.geom.Point;

    public class Util
    {

        [Embed(source='/assets/seeds.json', mimeType='application/octet-stream')]
        private static var SeedsJSON:Class;
        private static var seeds:Array;

        public static function secondsSince(d:Date):Number
        {
            return Number(((new Date().time - d.time) / 1000).toFixed(4));
        }

        public static function log(v:*):void
        {
            trace(v);
        }

        public static function toArray(iterable:*):Array
        {
            var arr:Array = [];
            for each (var elem:* in iterable)
                arr.push(elem);
            return arr;
        }

        public static function stringToSeed(str:String):Number
        {
            var hash:Number = 0;
            for (var i:int = 0; i < str.length; i++)
            {
                hash = ((hash << 5) - hash) + str.charCodeAt(i);
                hash = hash & hash;
            }

            return Math.abs(hash);
        }

        public static function closestPoint(point:Point, points:Array):Point
        {
            if (points.length == 0)
                return null;

            var closest:Point = points[0];

            do
            {
                var current:Point = points.shift();
                if (Point.distance(point, current) < Point.distance(point, closest))
                    closest = current;
            } while (points.length > 0);

            return closest;
        }

        public static function fixed(n:Number, places:int = 2):Number
        {
            return Number(n.toFixed(places));
        }

        public static function capitalizeFirstLetter(str:String):String
        {
            if (str.length == 0)
                return str;

            if (str.length == 1)
                return str.charAt(0).toUpperCase();
            else
                return str.charAt(0).toUpperCase() + str.substr(1);
        }

        public static function colorBetweenColors(color1:uint = 0xFFFFFF, color2:uint = 0x000000, percent:Number = 0.5):uint
        {
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

        public static function roundToNearest(n:Number, m:Number):Number
        {
            return int(n / m) * m
        }

        public static function distanceBetweenTwoPoints(point1:Point, point2:Point):Number
        {
            return Math.sqrt((point1.x - point2.x) * (point1.x - point2.x) + (point1.y - point2.y) * (point1.y - point2.y));
        }

        public static function angleBetweenTwoPoints(p1:Point, p2:Point):Number
        {
            return toDegrees(Math.atan2(p2.y - p1.y, p2.x - p1.x));
        }

        public static function differenceBetweenTwoDegrees(d1:Number, d2:Number):Number
        {
            var m:Number = Math.abs((d1 + 180 - d2) % 360 - 180);
            return m;
        }

        public static function toDegrees(value:Number):Number
        {
            return value * 180 / Math.PI;
        }

        public static function toRadians(value:Number):Number
        {
            return value * Math.PI / 180
        }

        public static function pointFromAngleAndDistance(point:Point, degrees:Number, distance:Number):Point
        {
            var r:Number = toRadians(degrees);
            return new Point(point.x + Math.cos(r) * distance, point.y + Math.sin(r) * distance);
        }

        public static function randomSeedPhrase():String
        {
            if (!seeds)
                seeds = JSON.parse(new SeedsJSON()).seeds;

            return seeds[int(Math.random() * seeds.length - 1)];
        }
    }
}