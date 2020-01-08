package layers {
    import flash.geom.Point;

    import global.Direction;

    import graph.Cell;

    public class AirParticle {
        public var point:Point;
        public var direction:Number;
        public var speed:Number;
        public var moisture:Number;

        public var from:AirParticle;
        public var height:Number;

        public var north:AirParticle = null;
        public var south:AirParticle = null;

        public function AirParticle(point:Point, direction:Number, speed:Number) {
            this.point = point;
            this.direction = direction;
            this.speed = speed;
        }

        public function step():AirParticle {
            var neighbor:AirParticle;
            if (direction == Direction.NORTH) neighbor = north;
            else if (direction == Direction.SOUTH) neighbor = south;

            if (neighbor) {
                if (neighbor.speed < speed) {
                    neighbor.moisture = moisture;
                    neighbor.direction = direction;
                    neighbor.speed = speed;
                    neighbor.from = this;
                } else {
                    return null;
                }
            }

            return neighbor;
        }
    }
}