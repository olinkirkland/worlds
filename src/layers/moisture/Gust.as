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

        public var index:int;


        public function Gust(point:Point,
                             size:Number) {
            this.point = point;
            this.size = size;

            corners = [point, new Point(point.x + size, point.y), new Point(point.x + size, point.y + size), new Point(point.x, point.y + size)];

            neighbors = {0: null, 90: null, 180: null, 270: null};
        }

        public function sendForce():Array {
            return [];
        }

        public function receiveForce(incomingAngle:Number, incomingStrength:Number):void {

        }

        public function setNeighbor(gust:Gust,
                                    degrees:Number):void {
            neighbors[degrees] = gust;
        }

        public function reset():void {
            angle = Direction.SOUTH;
            strength = 0;
            index = -1;
        }
    }
}
