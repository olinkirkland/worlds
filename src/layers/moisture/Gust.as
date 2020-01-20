package layers.moisture {
    import flash.geom.Point;

    import global.Direction;

    import global.Util;


    public class Gust {
        public var used:Boolean;

        public var point:Point;
        public var radius:Number;
        public var height:Number;

        public var angle:Number;
        public var strength:Number;

        public var neighbors:Object;

        public var index:int;


        public function Gust(point:Point,
                             radius:Number) {
            this.point = point;
            this.radius = radius;

            neighbors = {0: null, 90: null, 180: null, 270: null};
        }

        public function sendForce():Array {

        }

        public function receiveForce(incomingAngle:Number, incomingStrength:Number):void {

        }

        public function setNeighbor(hex:Gust,
                                    degrees:Number):void {
            neighbors[degrees] = hex;
        }

        public function reset():void {
            angle = Direction.SOUTH;
            strength = 0;
            index = -1;
        }
    }
}
