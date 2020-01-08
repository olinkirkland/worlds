package layers {
    import flash.geom.Point;

    import global.Util;

    public class AirParticle {
        public var point:Point;
        public var direction:Number;
        public var strength:Number;

        public var north:AirParticle = null;
        public var east:AirParticle = null;
        public var south:AirParticle = null;
        public var west:AirParticle = null;

        public function AirParticle(point:Point, direction:Number, strength:Number) {
            this.point = point;
            this.direction = direction;
            this.strength = strength;
        }
    }
}
