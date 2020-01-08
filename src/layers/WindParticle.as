package layers {
    import flash.geom.Point;

    import global.Util;

    public class WindParticle {
        public var point:Point;
        public var direction:Number;
        public var speed:Number;
        public var rotation:Number;

        public var from:WindParticle;
        public var to:WindParticle;

        public function WindParticle(point:Point, direction:Number, speed:Number, rotation:Number) {
            this.point = point;
            this.direction = direction;
            this.speed = speed;
            this.rotation = rotation;

            trace("dir=" + direction + ", spd=" + speed + ", rot=" + rotation);
        }

        public function step():WindParticle {
            to = new WindParticle(Util.pointFromAngleAndDistance(point, direction, speed), direction + rotation, speed * .9, rotation);
            to.from = this;
            return to;
        }
    }
}
