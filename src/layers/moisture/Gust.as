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
        public var precipitation:Number;

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

        public function send():Array {
            if (strength == 0)
                return [];

            var carry:Boolean;
            var neighbor:Gust = neighbors[angle];
            if (neighbor) {
                var heightDifference:Number = 1 - (neighbor.height - height) * 2;

                // Decrease speed going uphill (and increase going downhill)
                var outgoingStrength:Number = strength * heightDifference;

                if (ocean) {
                    // Pick up moisture from the water
                    if (moisture < 25)
                        moisture += 3;

                    precipitation = 0;
                    // Pick up speed from the ocean
                    outgoingStrength *= 1.5;
                } else {
                    // Drop moisture onto land as precipitation
                    if (moisture > 0) {
                        precipitation = Math.min(moisture, heightDifference * 2);
                        moisture -= precipitation * 1.5;
                        precipitation = Math.min(precipitation / 3, 1);
                    }
                    // Decrease speed over land
                    outgoingStrength *= .9;
                }

                outgoingStrength = Math.min(outgoingStrength, 25);

                carry = neighbor.receive(angle, outgoingStrength, moisture);
            }

            return neighbor && carry ? [neighbor] : [];
        }

        public function receive(incomingAngle:Number, incomingStrength:Number, incomingMoisture:Number):Boolean {
            if (strength > incomingStrength)
                return false;

            angle = incomingAngle;
            strength = incomingStrength;
            moisture = incomingMoisture;

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
