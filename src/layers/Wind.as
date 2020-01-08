package layers {
    import flash.geom.Point;

    import global.Direction;

    public class Wind {
        private var map:Map;

        public var windParticles:Vector.<WindParticle>;

        public function Wind(map:Map) {
            var minimumSpacing:Number = 15;
            var horizontalSpacing:int = map.width / (map.width / minimumSpacing);
            var verticalSpacing:int = map.height / (map.height / minimumSpacing);

            windParticles = new Vector.<WindParticle>();
            // Spawn starting wind particles on the top and bottom of the map pointing toward the center
            var w:WindParticle;
            //for (var i:int = horizontalSpacing; i < map.width; i += horizontalSpacing) {
            // Polar
            windParticles.push(new WindParticle(new Point(map.width / 2, map.height / 2), Direction.SOUTH, 100, 1));
            //windParticles.push(new WindParticle(new Point(i, map.height - verticalSpacing), Direction.NORTH, 100, 2));
            //}

            var queue:Vector.<WindParticle> = windParticles.concat();
            while (queue.length > 0) {
                w = queue.pop();
                var v:WindParticle = w.step();
                //map.bounds.contains(v.point.x, v.point.y) &&
                if (v.speed > .2) {
                    windParticles.push(v);
                    queue.push(v);
                }
            }
        }
    }
}
