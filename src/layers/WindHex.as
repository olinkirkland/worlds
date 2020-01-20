package layers {
    import flash.geom.Point;

    import global.Direction;

    import global.Util;


    public class WindHex {
        public var used:Boolean;

        public var point:Point;
        public var radius:Number;
        public var height:Number;

        public var angle:Number;
        public var strength:Number;

        public var corners:Array;
        public var neighbors:Object;

        public var index:int;


        public function WindHex(point:Point,
                                radius:Number) {
            this.point = point;
            this.radius = radius;

            neighbors = {0: null, 60: null, 120: null, 180: null, 240: null, 300: null};

            determineCorners();
        }

        public function propagate():Array {


            // Determine what neighbors receive force from this hex
            var targetAngle1:Number = Math.floor(angle / 60) * 60;
            var targetAngle2:Number = targetAngle1 + 60;
            if (targetAngle2 >= 360)
                targetAngle2 -= 360;

            var totalPortion:Number = Util.differenceBetweenTwoDegrees(targetAngle1, targetAngle2);
            trace("tp=" + totalPortion);
            trace("ta1=" + targetAngle1 + ", ta2=" + targetAngle2);
            trace("angle=" + angle);
            var targetPortion1:Number = Util.differenceBetweenTwoDegrees(targetAngle2, angle) / totalPortion * strength;
            var targetPortion2:Number = Util.differenceBetweenTwoDegrees(targetAngle1, angle) / totalPortion * strength;

            trace("tp1=" + targetPortion1 + ", tp2" + targetPortion2);


            if (strength < 0.1)
                return [];

            var targets:Array = [];

            // Target 1
            var target1:WindHex = neighbors[String(targetAngle1)];
            if (target1) {
                target1.incomingForce(targetAngle1, targetPortion1);
                targets.push(target1);
            }

            // Target 2
            var target2:WindHex = neighbors[String(targetAngle2)];
            if (target2 && targetPortion2 > 0) {
                target2.incomingForce(targetAngle2, targetPortion2);
                targets.push(target2);
            }

            return targets;
        }

        public function incomingForce(incomingAngle:Number, incomingStrength:Number):void {
            // Combine the incoming force with the current one (vector sum)
            var origin:Point = new Point(0, 0);

            var destination:Point = Util.pointFromDegreesAndDistance(origin, angle, strength);

            var combinedDestination:Point = Util.pointFromDegreesAndDistance(destination, incomingAngle, incomingStrength);
            angle = Math.floor(Util.angleBetweenTwoPoints(origin, combinedDestination));
            strength = Util.distanceBetweenTwoPoints(origin, combinedDestination);
            if (angle < 0)
                angle += 360;
        }


        public function determineCorners():void {
            corners = [];
            for (var i:int = 0; i < 6; i++) {
                corners.push(determineCorner(i));
            }
        }

        private function determineCorner(i:int):Point {
            var angle:Number = Util.toRadians(60 * i - 30);
            return new Point(point.x + radius * Math.cos(angle),
                    point.y + radius * Math.sin(angle));
        }

        public function setNeighbor(hex:WindHex,
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
