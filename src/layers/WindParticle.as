package layers {
    import flash.geom.Point;

    public class WindParticle {
        public var point:Point;
        public var direction:Number;

        public function WindParticle(point:Point, direction:Number) {
            this.point = point;
            this.direction = direction;
        }

        public function step():void {
        }
    }
}
