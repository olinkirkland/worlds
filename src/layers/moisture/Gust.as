package layers.moisture {
    import flash.geom.Point;

    import global.Direction;

    import global.Util;


    public class Gust {
        public var used:Boolean;

        public var point:Point;
        public var size:Number;
        public var height:Number;

        public var corners:Array;

        public var angle:Number;
        public var strength:Number;

        public var neighbors:Object;
        public var ocean:Boolean;
        public var moisture:Number;


        public function Gust(point:Point,
                             size:Number) {
            this.point = point;
            this.size = size;

            corners = [new Point(point.x, point.y),
                new Point(point.x + size, point.y),
                new Point(point.x + size, point.y + size),
                new Point(point.x, point.y + size)];

            point.x += size / 2;
            point.y += size / 2;

            neighbors = {0: null, 90: null, 180: null, 270: null};
        }

        public function sendForce():Array {
            if (strength == 0)
                return [];

            var carry:Boolean;
            var neighbor:Gust = neighbors[angle];
            if (neighbor) {
                var f:Number = strength * ((1 - (neighbor.height - height) * 2));
                f *= neighbor.ocean ? 1.5 : .9;
                f = Math.min(f, 25);
                carry = neighbor.receiveForce(angle, f);
            }

            return neighbor && carry ? [neighbor] : [];
        }

        public function receiveForce(incomingAngle:Number, incomingStrength:Number):Boolean {
            if (strength > incomingStrength)
                return false;

            angle = incomingAngle;
            strength = incomingStrength;

            if (strength < 1)
                strength = 0;

            return true;
        }

        public function setNeighbor(gust:Gust,
                                    degrees:Number):void {
            neighbors[degrees] = gust;
        }

        public function reset():void {
            angle = Direction.SOUTH;
            strength = 0;
            ocean = false;
        }
    }
}
